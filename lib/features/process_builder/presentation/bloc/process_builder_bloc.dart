import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../../roles/domain/usecases/get_roles_by_department_usecase.dart';
import '../../../type_processes/domain/usecases/get_type_processes_usecase.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
import '../../domain/usecases/configure_stages_usecase.dart';
import '../../domain/usecases/create_process_definition_usecase.dart';
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

  ProcessBuilderBloc({
    required this.createProcess,
    required this.configureStages,
    required this.getTypeProcesses,
    required this.getOrganizations,
    required this.getLeafDepartments,
    required this.getRolesByDepartment,
  }) : super(const ProcessBuilderState()) {
    on<InitWizard>(_onInit);
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
    on<StageOrgChanged>(_onStageOrg);
    on<StageDeptChanged>(_onStageDept);
    on<StageRoleChanged>(_onStageRole);
    on<StageWidgetToggled>(_onStageWidget);
    on<StageSignatureToggled>(_onStageSignature);
    on<StageActionToggled>(_onStageAction);
    on<SubmitStageConfigs>(_onSubmitStageConfigs);
  }

  // ── bootstrap ───────────────────────────────────────────────────────────
  Future<void> _onInit(
    InitWizard event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    emit(state.copyWith(bootStatus: RequestStatus.loading));

    final orgsResult = await getOrganizations();
    final typesResult = await getTypeProcesses();

    emit(state.copyWith(
      bootStatus: RequestStatus.success,
      organizations: orgsResult.getOrElse(() => const []),
      typeProcesses: typesResult.getOrElse(() => const []),
      // Preselect the type the wizard was opened for (null = شكوى / unset).
      typeTransId: event.typeId,
    ));
  }

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
        final drafts = <int, StageConfigDraft>{
          for (final s in process.stages) s.id: StageConfigDraft(stage: s),
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

    if (draft == null) return;

    // Re-fetch the cascade for whatever this stage already had selected.
    if (draft.organizationId != null) {
      await _fetchLeaves(draft.organizationId!, event.stageId, emit);
    }
    if (draft.departmentId != null) {
      await _fetchRoles(draft.departmentId!, event.stageId, emit);
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

  void _onStageAction(
    StageActionToggled event,
    Emitter<ProcessBuilderState> emit,
  ) {
    // Actions belong to SERVICE_TASK only — the backend rejects them on a
    // USER_TASK config_json. Guard at the source.
    final target = state.drafts[event.stageId];
    if (target == null || !target.stage.isServiceTask) return;

    _updateDraft(event.stageId, emit, (d) {
      final actions = [...d.actions];
      actions.remove(event.action);
      if (event.selected) actions.add(event.action);
      return d.copyWith(actions: actions);
    });
  }

  // ── final submit: stage_config only ─────────────────────────────────────
  Future<void> _onSubmitStageConfigs(
    SubmitStageConfigs event,
    Emitter<ProcessBuilderState> emit,
  ) async {
    if (!state.allStagesReady) {
      emit(state.copyWith(
        actionError:
            'يجب تحديد التعيين (مؤسسة/قسم/دور) لكل مهمة مستخدم قبل الحفظ.',
      ));
      return;
    }

    emit(state.copyWith(submitStatus: FormStatus.submitting, submitError: null));

    final stages =
        state.drafts.values.map((d) => d.toRequestJson()).toList();

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
    Emitter<ProcessBuilderState> emit,
  ) async {
    emit(state.copyWith(
      leafStatus: RequestStatus.loading,
      leafDepartments: const [],
    ));
    final result = await getLeafDepartments(organizationId);

    // Drop a stale result: the user switched stages or changed the org while
    // this request was in flight.
    if (state.expandedStageId != stageId ||
        state.drafts[stageId]?.organizationId != organizationId) {
      return;
    }

    result.fold(
      (failure) => emit(state.copyWith(
        leafStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (leaves) => emit(state.copyWith(
        leafStatus: RequestStatus.success,
        leafDepartments: leaves,
      )),
    );
  }

  Future<void> _fetchRoles(
    int departmentId,
    int stageId,
    Emitter<ProcessBuilderState> emit,
  ) async {
    emit(state.copyWith(
      rolesStatus: RequestStatus.loading,
      rolesByDepartment: const [],
    ));
    final result = await getRolesByDepartment(departmentId);

    // Drop a stale result (stage switched or dept changed mid-flight).
    if (state.expandedStageId != stageId ||
        state.drafts[stageId]?.departmentId != departmentId) {
      return;
    }

    result.fold(
      (failure) => emit(state.copyWith(
        rolesStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (roles) => emit(state.copyWith(
        rolesStatus: RequestStatus.success,
        rolesByDepartment: roles,
      )),
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
