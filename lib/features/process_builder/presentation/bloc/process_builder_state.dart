import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../../institutions/domain/entities/institution.dart';
import '../../../roles/domain/entities/role_by_department.dart';
import '../../../templates/domain/entities/doc_template.dart';
import '../../../type_processes/domain/entities/type_process.dart';
import '../../domain/entities/created_process.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
import '../../domain/entities/widget_config.dart';

class ProcessBuilderState extends Equatable {
  /// Current wizard step (1..4).
  final int currentStep;

  /// Bootstrap load (organizations + types). The field library lives in
  /// [FieldsBloc], not here.
  final RequestStatus bootStatus;
  final List<Institution> organizations;
  final List<TypeProcess> typeProcesses;

  /// Document templates (for the USER_TASK template picker + GENERATE_PDF).
  final List<DocTemplate> templates;

  // ── step 1 ──────────────────────────────────────────────────────────────
  final String name;
  final bool isComplaint;
  final int? typeTransId;
  final int? organizationId;
  final int priority;
  final DateTime? startDate;
  final DateTime? endDate;

  // ── step 2 ──────────────────────────────────────────────────────────────
  final List<int>? fileBytes;
  final String? fileName;

  // create call
  final RequestStatus createStatus;
  final String? createError;
  final CreatedProcess? createdProcess;

  /// True when the wizard was opened to COMPLETE an existing process (step 4
  /// only): some stages may be locked, and submit sends only the missing ones.
  final bool completeMode;

  // ── step 4 ──────────────────────────────────────────────────────────────
  final Map<int, StageConfigDraft> drafts;

  /// The stage whose card is currently expanded (inline editor); null = all
  /// collapsed.
  final int? expandedStageId;

  // assignment cascade for the currently expanded stage
  final RequestStatus leafStatus;
  final List<LeafDepartment> leafDepartments;
  final RequestStatus rolesStatus;
  final List<RoleByDepartment> rolesByDepartment;

  // final submit (stage_config only)
  final FormStatus submitStatus;
  final String? submitError;

  /// One-shot error surfaced as a snackbar.
  final String? actionError;

  const ProcessBuilderState({
    this.currentStep = 1,
    this.bootStatus = RequestStatus.initial,
    this.organizations = const [],
    this.typeProcesses = const [],
    this.templates = const [],
    this.name = '',
    this.isComplaint = false,
    this.typeTransId,
    this.organizationId,
    this.priority = 2,
    this.startDate,
    this.endDate,
    this.fileBytes,
    this.fileName,
    this.createStatus = RequestStatus.initial,
    this.createError,
    this.createdProcess,
    this.completeMode = false,
    this.drafts = const {},
    this.expandedStageId,
    this.leafStatus = RequestStatus.initial,
    this.leafDepartments = const [],
    this.rolesStatus = RequestStatus.initial,
    this.rolesByDepartment = const [],
    this.submitStatus = FormStatus.idle,
    this.submitError,
    this.actionError,
  });

  bool get hasFile => fileBytes != null && fileBytes!.isNotEmpty;

  StageConfigDraft? get expandedDraft =>
      expandedStageId == null ? null : drafts[expandedStageId];

  /// All USER_TASK stages must have a complete assignment before submit.
  bool get allStagesReady => drafts.values.every((d) => d.isComplete);

  /// Template ids linked to any USER_TASK stage. A GENERATE_PDF action may only
  /// target one of these — otherwise no `document_instance` exists at run-time
  /// and generation fails. Returned as the [DocTemplate]s for display.
  List<DocTemplate> get linkedTemplates {
    final linkedIds = <int>{
      for (final d in drafts.values)
        if (d.stage.isUserTask) ...d.templateIds,
    };
    return templates.where((t) => linkedIds.contains(t.id)).toList();
  }

  /// The widgets a SYNC_SELF_CARD on [stageId] can read values from: every
  /// widget of the USER_TASK stages that come BEFORE it in the BPMN order.
  ///
  /// The sync reads a *sealed* snapshot of an earlier USER_TASK
  /// (`source_stage: PREVIOUS_USER_TASK`), so a widget from a later stage —
  /// or from the service task itself — has no value at run-time. Offering only
  /// upstream widgets keeps an unresolvable mapping from being built at all.
  List<WidgetConfig> sourceWidgetsFor(int stageId) {
    final ordered = createdProcess?.stages ?? const <ProcessStage>[];
    final index = ordered.indexWhere((s) => s.id == stageId);
    if (index < 0) return const [];

    final seen = <String>{};
    final result = <WidgetConfig>[];
    for (final stage in ordered.take(index)) {
      if (!stage.isUserTask) continue;
      for (final w in drafts[stage.id]?.widgets ?? const <WidgetConfig>[]) {
        // The picker itself is the card selector, not a value to map.
        if (w.widgetType == 'employee_picker') continue;
        if (seen.add(w.widgetId)) result.add(w);
      }
    }
    return result;
  }

  /// Whether any USER_TASK before [stageId] carries the `employee_picker`.
  /// Without one the sync cannot resolve which card to write to and fails at
  /// run-time, so the wizard warns about it up front.
  bool hasUpstreamSelfCardPicker(int stageId) {
    final ordered = createdProcess?.stages ?? const <ProcessStage>[];
    final index = ordered.indexWhere((s) => s.id == stageId);
    if (index < 0) return false;
    return ordered.take(index).any(
          (s) => s.isUserTask && (drafts[s.id]?.hasSelfCardPicker ?? false),
        );
  }

  ProcessBuilderState copyWith({
    int? currentStep,
    RequestStatus? bootStatus,
    List<Institution>? organizations,
    List<TypeProcess>? typeProcesses,
    List<DocTemplate>? templates,
    String? name,
    bool? isComplaint,
    int? typeTransId,
    bool clearType = false,
    int? organizationId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    List<int>? fileBytes,
    String? fileName,
    RequestStatus? createStatus,
    String? createError,
    CreatedProcess? createdProcess,
    bool? completeMode,
    Map<int, StageConfigDraft>? drafts,
    int? expandedStageId,
    bool clearExpanded = false,
    RequestStatus? leafStatus,
    List<LeafDepartment>? leafDepartments,
    RequestStatus? rolesStatus,
    List<RoleByDepartment>? rolesByDepartment,
    FormStatus? submitStatus,
    String? submitError,
    String? actionError,
  }) {
    return ProcessBuilderState(
      currentStep: currentStep ?? this.currentStep,
      bootStatus: bootStatus ?? this.bootStatus,
      organizations: organizations ?? this.organizations,
      typeProcesses: typeProcesses ?? this.typeProcesses,
      templates: templates ?? this.templates,
      name: name ?? this.name,
      isComplaint: isComplaint ?? this.isComplaint,
      typeTransId: clearType ? null : (typeTransId ?? this.typeTransId),
      organizationId: organizationId ?? this.organizationId,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      createStatus: createStatus ?? this.createStatus,
      createError: createError,
      createdProcess: createdProcess ?? this.createdProcess,
      completeMode: completeMode ?? this.completeMode,
      drafts: drafts ?? this.drafts,
      expandedStageId:
          clearExpanded ? null : (expandedStageId ?? this.expandedStageId),
      leafStatus: leafStatus ?? this.leafStatus,
      leafDepartments: leafDepartments ?? this.leafDepartments,
      rolesStatus: rolesStatus ?? this.rolesStatus,
      rolesByDepartment: rolesByDepartment ?? this.rolesByDepartment,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        bootStatus,
        organizations,
        typeProcesses,
        templates,
        name,
        isComplaint,
        typeTransId,
        organizationId,
        priority,
        startDate,
        endDate,
        fileName,
        fileBytes?.length,
        createStatus,
        createError,
        createdProcess,
        completeMode,
        drafts,
        expandedStageId,
        leafStatus,
        leafDepartments,
        rolesStatus,
        rolesByDepartment,
        submitStatus,
        submitError,
        actionError,
      ];
}
