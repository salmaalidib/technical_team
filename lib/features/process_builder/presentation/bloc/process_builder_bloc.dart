import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../../roles/domain/entities/role_by_department.dart';
import '../../../roles/domain/usecases/get_roles_by_department_usecase.dart';
import '../../../templates/domain/usecases/get_templates_usecase.dart';
import '../../../type_processes/domain/usecases/get_type_processes_usecase.dart';
import '../../domain/entities/created_process.dart';
import '../../domain/entities/notification_action_config.dart';
import '../../domain/entities/process_details.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
import '../../domain/usecases/configure_stages_usecase.dart';
import '../../domain/usecases/create_process_definition_usecase.dart';
import '../../domain/usecases/get_process_details_usecase.dart';
import 'process_builder_event.dart';
import 'process_builder_state.dart';

class ProcessBuilderBloc
    extends Bloc<ProcessBuilderEvent, ProcessBuilderState> {
  final CreateProcessDefinitionUseCase createProcess;
  final ConfigureStagesUseCase configureStages;
  final GetTypeProcessesUseCase getTypeProcesses;
  final GetInstitutionsUseCase getOrganizations;
  final GetLeafDepartmentsUseCase getLeafDepartments;
  final GetRolesByDepartmentUseCase getRolesByDepartment;
  final GetTemplatesUseCase getTemplates;
  final GetProcessDetailsUseCase getProcessDetails;

  ProcessBuilderBloc({
    required this.createProcess,
    required this.configureStages,
    required this.getTypeProcesses,
    required this.getOrganizations,
    required this.getLeafDepartments,
    required this.getRolesByDepartment,
    required this.getTemplates,
    required this.getProcessDetails,
  }) : super(const ProcessBuilderState()) {
    on<InitWizard>(_onInit);
    on<LoadExistingForStageConfig>(_onLoadExisting);
    on<StepRequested>(_onStep);
    on<NameChanged>((e, emit) => emit(state.copyWith(name: e.name)));
    on<ComplaintChanged>(_onComplaintChanged);
    on<TypeChanged>((e, emit) => emit(state.copyWith(typeTransId: e.typeTransId)));
    on<OrganizationChanged>(
        (e, emit) => emit(state.copyWith(organizationId: e.organizationId)));
    on<PriorityChanged>((e, emit) => emit(state.copyWith(priority: e.priority)));
    on<StartDateChanged>((e, emit) => emit(state.copyWith(startDate: e.date)));
    on<EndDateChanged>((e, emit) => emit(
        state.copyWith(endDate: e.date, clearEndDate: e.date == null)));
    on<FileSelected>((e, emit) =>
        emit(state.copyWith(fileBytes: e.bytes, fileName: e.fileName)));
    on<SubmitCreate>(_onSubmitCreate);
    on<StageExpansionToggled>(_onStageExpansionToggled);
    on<StageAssigneeTypeChanged>(_onStageAssigneeType);
    on<StageOrgChanged>(_onStageOrg);
    on<StageDeptChanged>(_onStageDept);
    on<StageRoleChanged>(_onStageRole);
    on<StageWidgetToggled>(_onStageWidget);
    on<StageSignatureToggled>(_onStageSignature);
    on<StageTemplateToggled>(_onStageTemplate);
    on<StageActionToggled>(_onStageAction);
    on<StageNotificationMessageChanged>(_onNotificationMessage);
    on<StageNotificationTitleChanged>(_onNotificationTitle);
    on<StageNotificationRecipientChanged>(_onNotificationRecipient);
    on<StageNotificationOrgChanged>(_onNotificationOrg);
    on<StageNotificationDeptChanged>(_onNotificationDept);
    on<StageNotificationRoleChanged>(_onNotificationRole);
    on<StageGeneratePdfTemplateChanged>(_onGeneratePdfTemplate);
    on<SubmitStageConfigs>(_onSubmitStageConfigs);
  }

  /// The user's active organization — chosen once after login and reused
  /// everywhere instead of a per-form picker. Stages, notifications and the
  /// create payload all default to it; the org dropdowns are hidden.
  int? get _activeOrgId => getIt<ActiveOrganizationCubit>().activeOrgId;

  /// Per-wizard caches for the assignee cascade. The department/role lists for a
  /// given org/dept never change during one wizard session, yet every stage-card
  /// expansion used to re-fetch them — with ~10 stages sharing one organization
  /// that was dozens of duplicate requests. Keyed by organizationId / departmentId,
  /// they make each unique cascade a single network call for the whole wizard.
  final Map<int, List<LeafDepartment>> _leavesCache = {};
  final Map<int, List<RoleByDepartment>> _rolesCache = {};

  // ── bootstrap ───────────────────────────────────────────────────────────
  Future<void> _onInit(
    InitWizard event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    emit(state.copyWith(bootStatus: RequestStatus.loading));

    final orgsResult = await getOrganizations();
    final typesResult = await getTypeProcesses();
    // Templates feed the USER_TASK template picker and the GENERATE_PDF action.
    final templatesResult = await getTemplates();

    emit(state.copyWith(
      bootStatus: RequestStatus.success,
      organizations: orgsResult.getOrElse(() => const []),
      typeProcesses: typesResult.getOrElse(() => const []),
      templates: templatesResult.getOrElse(() => const []),
      // The organization is the active one — no step-1 picker.
      organizationId: _activeOrgId,
      // Preselect the type the wizard was opened for (null = شكوى / unset).
      typeTransId: event.typeId,
    ));
  }

  // ── complete-mode: load an existing process straight into step 4 ─────────
  Future<void> _onLoadExisting(
    LoadExistingForStageConfig event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    emit(state.copyWith(
      bootStatus: RequestStatus.loading,
      completeMode: true,
      currentStep: 4,
    ));

    // Cascade dropdowns + the template picker need orgs/templates loaded too.
    final orgsResult = await getOrganizations();
    final templatesResult = await getTemplates();
    final detailsResult = await getProcessDetails(event.processId);

    detailsResult.fold(
      (failure) => emit(state.copyWith(
        bootStatus: RequestStatus.failure,
        createError: failure.message,
      )),
      (details) {
        final stages =
            details.stages.map(_toProcessStage).toList(growable: false);

        final drafts = <int, StageConfigDraft>{
          for (final s in details.stages) s.id: _draftFromDetailStage(s),
        };

        // Expand the first stage still needing configuration.
        final firstMissing = details.stages.firstWhere(
          (s) => !s.hasConfig,
          orElse: () => details.stages.isNotEmpty
              ? details.stages.first
              : _placeholderDetail(),
        );

        emit(state.copyWith(
          bootStatus: RequestStatus.success,
          organizations: orgsResult.getOrElse(() => const []),
          templates: templatesResult.getOrElse(() => const []),
          createdProcess: CreatedProcess(
            id: details.process.id,
            name: details.process.name,
            code: details.process.code,
            status: details.process.status,
            stages: stages,
          ),
          drafts: drafts,
          currentStep: 4,
          expandedStageId: details.stages.isEmpty ? null : firstMissing.id,
          clearExpanded: details.stages.isEmpty,
        ));
      },
    );
  }

  static ProcessStage _toProcessStage(ProcessDetailStage s) => ProcessStage(
        id: s.id,
        name: s.name,
        code: s.code ?? '',
        type: s.type ?? 'SERVICE_TASK',
        authType: s.authType ?? 'NOAUTH',
      );

  /// Builds a draft for an existing stage. Already-configured stages are locked
  /// (read-only, not re-submitted); their linked template ids are recovered
  /// from the saved config so a later GENERATE_PDF can still reference them.
  static StageConfigDraft _draftFromDetailStage(ProcessDetailStage s) {
    if (s.hasConfig) {
      // Saved stage: keep it locked and DON'T touch its organization.
      final templateIds = _templateIdsFromConfig(s.config);
      return StageConfigDraft(stage: _toProcessStage(s))
          .copyWith(locked: true, templateIds: templateIds);
    }
    // Unconfigured stage: default its assignment to the active organization.
    return StageConfigDraft(
      stage: _toProcessStage(s),
      organizationId: getIt<ActiveOrganizationCubit>().activeOrgId,
    );
  }

  static List<int> _templateIdsFromConfig(Map<String, dynamic>? config) {
    final raw = config?['template'];
    if (raw is! List) return const [];
    return raw
        .map((e) => e is Map ? (e['template_id'] as num?)?.toInt() : null)
        .whereType<int>()
        .toList();
  }

  static ProcessDetailStage _placeholderDetail() => const ProcessDetailStage(
        id: -1,
        name: '',
        hasConfig: false,
        hasAssignments: false,
      );

  void _onStep(StepRequested event, Emitter<ProcessBuilderState> emit) {
    emit(state.copyWith(currentStep: event.step));
  }

  void _onComplaintChanged(
    ComplaintChanged event,
    Emitter<ProcessBuilderState> emit,
  ) {
    // شكوى → no process type.
    emit(state.copyWith(
      isComplaint: event.isComplaint,
      clearType: event.isComplaint,
    ));
  }

  // ── create (step 2 → 3) ─────────────────────────────────────────────────
  Future<void> _onSubmitCreate(
    SubmitCreate event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    // Guard against double-submit while a create is already in flight.
    if (state.createStatus == RequestStatus.loading) return;

    // Defensive: these are validated by the UI before reaching step 2, but
    // never trust state for a force-unwrap.
    if (state.organizationId == null ||
        state.startDate == null ||
        state.fileBytes == null ||
        state.fileName == null) {
      emit(state.copyWith(
        createStatus: RequestStatus.failure,
        createError: 'بيانات ناقصة — تأكد من الاسم والمؤسسة والتاريخ والملف.',
      ));
      return;
    }

    emit(state.copyWith(
      createStatus: RequestStatus.loading,
      createError: null,
    ));

    final result = await createProcess(
      name: state.name,
      isComplaint: state.isComplaint,
      typeTransId: state.typeTransId,
      organizationId: state.organizationId!,
      priority: state.priority,
      startDate: _monthDay(state.startDate!),
      endDate: state.endDate == null ? null : _monthDay(state.endDate!),
      fileBytes: state.fileBytes!,
      fileName: state.fileName!,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        createStatus: RequestStatus.failure,
        createError: failure.message,
      )),
      (process) {
        // Each stage defaults to the active organization (no per-stage picker).
        final orgId = _activeOrgId;
        final drafts = <int, StageConfigDraft>{
          for (final s in process.stages)
            s.id: StageConfigDraft(stage: s, organizationId: orgId),
        };
        // Expand the first customizable (user) stage by default.
        final firstUser = process.stages.firstWhere(
          (s) => s.isUserTask,
          orElse: () =>
              process.stages.isNotEmpty ? process.stages.first : _placeholder(),
        );

        emit(state.copyWith(
          createStatus: RequestStatus.success,
          createdProcess: process,
          drafts: drafts,
          expandedStageId: process.stages.isEmpty ? null : firstUser.id,
          clearExpanded: process.stages.isEmpty,
          currentStep: 3,
        ));
      },
    );
  }

  // ── step 4: expand / collapse a stage card ──────────────────────────────
  Future<void> _onStageExpansionToggled(
    StageExpansionToggled event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    // Toggle: tapping the open card collapses it.
    if (state.expandedStageId == event.stageId) {
      emit(state.copyWith(clearExpanded: true));
      return;
    }

    final draft = state.drafts[event.stageId];

    // Atomically switch the expanded card AND clear the previous stage's
    // cascade, so no stale departments/roles flash under the new card.
    emit(state.copyWith(
      expandedStageId: event.stageId,
      leafStatus: RequestStatus.initial,
      leafDepartments: const [],
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));

    // Locked stages are read-only (no cascades to restore).
    if (draft == null || draft.locked) return;

    // Re-fetch the cascade for whatever this stage already had selected. A
    // USER_TASK uses its own assignment; a SERVICE_TASK with an employee-
    // recipient notification uses the notification cascade instead.
    if (draft.stage.isUserTask) {
      // A citizen assignee has no cascade to restore.
      if (draft.assigneeType == AssigneeType.employee) {
        if (draft.organizationId != null) {
          await _fetchLeaves(draft.organizationId!, event.stageId, emit);
        }
        if (draft.departmentId != null) {
          await _fetchRoles(draft.departmentId!, event.stageId, emit);
        }
      }
    } else if (draft.hasNotification &&
        draft.notification.recipient == NotificationRecipient.employee) {
      await _restoreNotificationCascade(event.stageId, emit);
    }
  }


  /// Toggles a USER_TASK between an employee assignee (org/dept/role cascade)
  /// and a citizen assignee (fixed role, no cascade). Mirrors
  /// [_onNotificationRecipient]: switching to employee seeds the active org and
  /// restores its cascade; switching to citizen just drops the cascade state.
  Future<void> _onStageAssigneeType(
    StageAssigneeTypeChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    final target = state.drafts[event.stageId];
    if (target == null || !target.stage.isUserTask) return;

    final toEmployee = event.assigneeType == AssigneeType.employee;
    _updateDraft(event.stageId, emit, (d) {
      var updated = d.copyWith(assigneeType: event.assigneeType);
      // An employee assignee defaults to the active organization (no picker);
      // seed it only when not already set so we don't clobber a prior choice.
      if (toEmployee && updated.organizationId == null) {
        updated = updated.copyWith(organizationId: _activeOrgId);
      }
      return updated;
    });

    // Reset the shared cascade state either way; for employee, reload it below.
    emit(state.copyWith(
      leafStatus: RequestStatus.initial,
      leafDepartments: const [],
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));

    if (!toEmployee) return;

    final draft = state.drafts[event.stageId];
    if (draft?.organizationId != null) {
      await _fetchLeaves(draft!.organizationId!, event.stageId, emit);
    }
    if (draft?.departmentId != null) {
      await _fetchRoles(draft!.departmentId!, event.stageId, emit);
    }
  }

  Future<void> _onStageOrg(
    StageOrgChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    // org change resets dept + role (via the copyWith clear flags).
    _updateDraft(
      event.stageId,
      emit,
      (d) => d.copyWith(
        organizationId: event.organizationId,
        clearDepartment: true,
        clearRole: true,
      ),
    );
    emit(state.copyWith(
      leafStatus: RequestStatus.initial,
      leafDepartments: const [],
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));
    if (event.organizationId != null) {
      await _fetchLeaves(event.organizationId!, event.stageId, emit);
    }
  }

  Future<void> _onStageDept(
    StageDeptChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    // dept change resets role.
    _updateDraft(
      event.stageId,
      emit,
      (d) => d.copyWith(departmentId: event.departmentId, clearRole: true),
    );
    emit(state.copyWith(
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));
    if (event.departmentId != null) {
      await _fetchRoles(event.departmentId!, event.stageId, emit);
    }
  }

  void _onStageRole(StageRoleChanged event, Emitter<ProcessBuilderState> emit) {
    _updateDraft(
        event.stageId, emit, (d) => d.copyWith(roleId: event.roleId));
  }

  void _onStageWidget(
    StageWidgetToggled event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(event.stageId, emit, (d) {
      final widgets = [...d.widgets];
      widgets.removeWhere((w) => w.widgetId == event.widget.widgetId);
      if (event.selected) widgets.add(event.widget);
      return d.copyWith(widgets: widgets);
    });
  }

  void _onStageSignature(
    StageSignatureToggled event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(event.stageId, emit,
        (d) => d.copyWith(requiresSignature: event.value));
  }

  void _onStageTemplate(
    StageTemplateToggled event,
    Emitter<ProcessBuilderState> emit,
  ) {
    // Templates link to USER_TASK config_json.template only.
    final target = state.drafts[event.stageId];
    if (target == null || !target.stage.isUserTask) return;

    _updateDraft(event.stageId, emit, (d) {
      final ids = [...d.templateIds]..remove(event.templateId);
      if (event.selected) ids.add(event.templateId);
      return d.copyWith(templateIds: ids);
    });
  }

  Future<void> _onStageAction(
    StageActionToggled event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    // Actions belong to SERVICE_TASK only — the backend rejects them on a
    // USER_TASK config_json. Guard at the source.
    final target = state.drafts[event.stageId];
    if (target == null || !target.stage.isServiceTask) return;

    _updateDraft(event.stageId, emit, (d) {
      final actions = [...d.actions];
      actions.remove(event.action);
      if (event.selected) actions.add(event.action);
      // Unselecting GENERATE_PDF drops its template so a stale id never ships.
      final clearPdf = event.action == 'GENERATE_PDF' && !event.selected;
      return d.copyWith(
        actions: actions,
        clearGeneratePdfTemplate: clearPdf,
      );
    });

    // Turning on SEND_NOTIFICATION with an employee recipient already chosen
    // (e.g. re-toggled) should restore its cascade. Default recipient is
    // citizen, so nothing to fetch on a fresh toggle.
    if (event.action == 'SEND_NOTIFICATION' && event.selected) {
      final n = state.drafts[event.stageId]?.notification;
      if (n != null && n.recipient == NotificationRecipient.employee) {
        await _restoreNotificationCascade(event.stageId, emit);
      }
    }
  }

  // ── SEND_NOTIFICATION config ────────────────────────────────────────────
  void _onNotificationMessage(
    StageNotificationMessageChanged event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(event.stageId, emit,
        (d) => d.copyWith(notification: d.notification.copyWith(
              message: event.message,
            )));
  }

  void _onNotificationTitle(
    StageNotificationTitleChanged event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(event.stageId, emit,
        (d) => d.copyWith(notification: d.notification.copyWith(
              title: event.title,
            )));
  }

  Future<void> _onNotificationRecipient(
    StageNotificationRecipientChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    final toEmployee = event.recipient == NotificationRecipient.employee;
    _updateDraft(event.stageId, emit, (d) {
      var notification = d.notification.copyWith(recipient: event.recipient);
      // An employee recipient defaults to the active organization (no picker);
      // seed it only when not already set so we don't clobber a prior choice.
      if (toEmployee && notification.organizationId == null) {
        notification = notification.copyWith(organizationId: _activeOrgId);
      }
      return d.copyWith(notification: notification);
    });

    // Switching to citizen drops the role cascade; switching to employee loads
    // the active organization's departments ready for selection.
    emit(state.copyWith(
      leafStatus: RequestStatus.initial,
      leafDepartments: const [],
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));

    if (toEmployee) {
      final orgId = state.drafts[event.stageId]?.notification.organizationId;
      if (orgId != null) {
        await _fetchLeaves(
          orgId,
          event.stageId,
          emit,
          organizationOf: (d) => d.notification.organizationId,
        );
      } else {
        await _restoreNotificationCascade(event.stageId, emit);
      }
    }
  }

  Future<void> _onNotificationOrg(
    StageNotificationOrgChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    _updateDraft(
      event.stageId,
      emit,
      (d) => d.copyWith(
        notification: d.notification.copyWith(
          organizationId: event.organizationId,
          clearDepartment: true,
          clearRole: true,
        ),
      ),
    );
    emit(state.copyWith(
      leafStatus: RequestStatus.initial,
      leafDepartments: const [],
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));
    if (event.organizationId != null) {
      await _fetchLeaves(
        event.organizationId!,
        event.stageId,
        emit,
        organizationOf: (d) => d.notification.organizationId,
      );
    }
  }

  Future<void> _onNotificationDept(
    StageNotificationDeptChanged event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    _updateDraft(
      event.stageId,
      emit,
      (d) => d.copyWith(
        notification: d.notification.copyWith(
          departmentId: event.departmentId,
          clearRole: true,
        ),
      ),
    );
    emit(state.copyWith(
      rolesStatus: RequestStatus.initial,
      rolesByDepartment: const [],
    ));
    if (event.departmentId != null) {
      await _fetchRoles(
        event.departmentId!,
        event.stageId,
        emit,
        departmentOf: (d) => d.notification.departmentId,
      );
    }
  }

  void _onNotificationRole(
    StageNotificationRoleChanged event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(event.stageId, emit,
        (d) => d.copyWith(notification: d.notification.copyWith(
              roleId: event.roleId,
            )));
  }

  void _onGeneratePdfTemplate(
    StageGeneratePdfTemplateChanged event,
    Emitter<ProcessBuilderState> emit,
  ) {
    _updateDraft(
      event.stageId,
      emit,
      (d) => d.copyWith(
        generatePdfTemplateId: event.templateId,
        clearGeneratePdfTemplate: event.templateId == null,
      ),
    );
  }

  /// Re-fetch the cascade for whatever the notification recipient already had
  /// selected (used on recipient switch / card expand).
  Future<void> _restoreNotificationCascade(
    int stageId,
    Emitter<ProcessBuilderState> emit,
  ) async {
    final n = state.drafts[stageId]?.notification;
    if (n == null) return;
    if (n.organizationId != null) {
      await _fetchLeaves(
        n.organizationId!,
        stageId,
        emit,
        organizationOf: (d) => d.notification.organizationId,
      );
    }
    if (n.departmentId != null) {
      await _fetchRoles(
        n.departmentId!,
        stageId,
        emit,
        departmentOf: (d) => d.notification.departmentId,
      );
    }
  }

  // ── final submit: stage_config only ─────────────────────────────────────
  Future<void> _onSubmitStageConfigs(
    SubmitStageConfigs event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    if (!state.allStagesReady) {
      // Pinpoint why: an incomplete SERVICE_TASK action, or a USER_TASK
      // missing its assignment.
      final notifIncomplete = state.drafts.values.any(
        (d) => d.stage.isServiceTask && d.hasNotification && !d.isComplete,
      );
      final pdfIncomplete = state.drafts.values.any(
        (d) =>
            !d.locked &&
            d.stage.isServiceTask &&
            d.hasGeneratePdf &&
            d.generatePdfTemplateId == null,
      );
      final String message;
      if (pdfIncomplete) {
        message = 'اختر القالب لإجراء «توليد PDF» قبل الحفظ.';
      } else if (notifIncomplete) {
        message =
            'أكمل إعداد الإشعار (النص والمُستلِم — أو المؤسسة/القسم/الدور للموظف) قبل الحفظ.';
      } else {
        message = 'يجب تحديد التعيين (مؤسسة/قسم/دور) لكل مهمة مستخدم قبل الحفظ.';
      }
      emit(state.copyWith(actionError: message));
      return;
    }

    // Locked stages already have a saved config — re-sending them is a 409.
    // Submit only the stages that still need configuration.
    final pending = state.drafts.values.where((d) => !d.locked).toList();

    if (pending.isEmpty) {
      emit(state.copyWith(
        actionError: 'لا توجد مراحل ناقصة لحفظها — كل المراحل مُهيأة مسبقاً.',
      ));
      return;
    }

    emit(state.copyWith(submitStatus: FormStatus.submitting, submitError: null));

    final stages = pending.map((d) => d.toRequestJson()).toList();

    final result = await configureStages(stages);

    result.fold(
      (failure) => emit(state.copyWith(
        submitStatus: FormStatus.failure,
        submitError: failure.message,
      )),
      (_) => emit(state.copyWith(submitStatus: FormStatus.success)),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  void _updateDraft(
    int stageId,
    Emitter<ProcessBuilderState> emit,
    StageConfigDraft Function(StageConfigDraft) update,
  ) {
    final draft = state.drafts[stageId];
    if (draft == null) return;
    final drafts = Map<int, StageConfigDraft>.from(state.drafts);
    drafts[stageId] = update(draft);
    emit(state.copyWith(drafts: drafts));
  }

  Future<void> _fetchLeaves(
    int organizationId,
    int stageId,
    Emitter<ProcessBuilderState> emit, {
    // Where the selected org lives on the draft. USER_TASK uses the draft's own
    // assignment; SEND_NOTIFICATION uses the notification config. The staleness
    // check reads from here so the two cascades don't cross-cancel.
    int? Function(StageConfigDraft d)? organizationOf,
  }) async {
    final readOrg = organizationOf ?? (d) => d.organizationId;

    // Serve from cache: the org's departments don't change mid-wizard, so a
    // repeat expansion of any stage on the same org skips the network entirely.
    final cached = _leavesCache[organizationId];
    if (cached != null) {
      emit(state.copyWith(
        leafStatus: RequestStatus.success,
        leafDepartments: cached,
      ));
      return;
    }

    emit(state.copyWith(
      leafStatus: RequestStatus.loading,
      leafDepartments: const [],
    ));
    final result = await getLeafDepartments(organizationId);

    // Drop a stale result: the user switched stages or changed the org while
    // this request was in flight.
    final current = state.drafts[stageId];
    if (state.expandedStageId != stageId ||
        current == null ||
        readOrg(current) != organizationId) {
      return;
    }

    result.fold(
      (failure) => emit(state.copyWith(
        leafStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (leaves) {
        _leavesCache[organizationId] = leaves;
        emit(state.copyWith(
          leafStatus: RequestStatus.success,
          leafDepartments: leaves,
        ));
      },
    );
  }

  Future<void> _fetchRoles(
    int departmentId,
    int stageId,
    Emitter<ProcessBuilderState> emit, {
    int? Function(StageConfigDraft d)? departmentOf,
  }) async {
    final readDept = departmentOf ?? (d) => d.departmentId;

    // Serve from cache: the department's roles don't change mid-wizard.
    final cached = _rolesCache[departmentId];
    if (cached != null) {
      emit(state.copyWith(
        rolesStatus: RequestStatus.success,
        rolesByDepartment: cached,
      ));
      return;
    }

    emit(state.copyWith(
      rolesStatus: RequestStatus.loading,
      rolesByDepartment: const [],
    ));
    final result = await getRolesByDepartment(departmentId);

    // Drop a stale result (stage switched or dept changed mid-flight).
    final current = state.drafts[stageId];
    if (state.expandedStageId != stageId ||
        current == null ||
        readDept(current) != departmentId) {
      return;
    }

    result.fold(
      (failure) => emit(state.copyWith(
        rolesStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (roles) {
        _rolesCache[departmentId] = roles;
        emit(state.copyWith(
          rolesStatus: RequestStatus.success,
          rolesByDepartment: roles,
        ));
      },
    );
  }

  static String _monthDay(DateTime date) => '${date.month}-${date.day}';

  static ProcessStage _placeholder() => const ProcessStage(
        id: -1,
        name: '',
        code: '',
        type: 'SERVICE_TASK',
        authType: 'NOAUTH',
      );
}
