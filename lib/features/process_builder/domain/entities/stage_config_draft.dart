import 'package:equatable/equatable.dart';

import 'notification_action_config.dart';
import 'process_stage.dart';
import 'stage_assignment_target.dart';
import 'widget_config.dart';

/// Who executes a USER_TASK: specific [employee] roles (one or more org/dept/role
/// targets) or the transaction owner [citizen] (no cascade — a fixed citizen role).
enum AssigneeType { employee, citizen }

/// The in-progress customization of one stage (step 4). Converted to the
/// backend `stages[]` entry on submit.
///
/// USER_TASK → form (widgets) + assignment (org/dept/role) [+ signature].
/// SERVICE_TASK → optional [actions] (GENERATE_PDF / SEND_NOTIFICATION; the
/// backend does not support SEND_EMAIL).
class StageConfigDraft extends Equatable {
  final ProcessStage stage;

  /// Who executes this USER_TASK (employee targets vs citizen). Defaults to
  /// [AssigneeType.employee] so existing behaviour is unchanged.
  final AssigneeType assigneeType;

  /// The committed dept/role targets of this USER_TASK. The backend takes an
  /// array, so a stage may be assigned to several roles at once and every
  /// matching employee sees the task. Empty for a citizen assignee (a single
  /// all-null entry is sent instead) and for SERVICE_TASKs.
  final List<StageAssignmentTarget> assignments;

  /// The organization every target of this stage belongs to. It is the user's
  /// active organization, seeded system-wide — there is no per-stage picker.
  final int? organizationId;

  /// The in-progress picker above the list: the dept/role currently being
  /// chosen, not yet added to [assignments]. Cleared after each add.
  final int? departmentId;
  final int? roleId;

  /// Selected field widgets (USER_TASK only), keyed by widgetId for dedup.
  final List<WidgetConfig> widgets;

  final bool requiresSignature;

  /// When true, the employees of THIS stage pick the destination of the NEXT
  /// stage at run-time (`POST /complete`) instead of it being pre-assigned.
  /// Serializes to `config_json.is_assignment`.
  ///
  /// It does NOT change who executes this stage: [assignments] still needs real
  /// employee targets, and the backend rejects the all-null CITIZEN shape while
  /// the flag is on (a citizen cannot route transactions).
  final bool isAssignment;

  /// Linked document templates (USER_TASK only). Serializes to
  /// `config_json.template = [{ template_id }]`; the citizen fills these in at
  /// run-time, creating the `document_instance` a later GENERATE_PDF consumes.
  final List<int> templateIds;

  /// Selected automatic actions (SERVICE_TASK only).
  final List<String> actions;

  /// Config for the SEND_NOTIFICATION action (message + recipient). Only
  /// meaningful while `actions` contains `SEND_NOTIFICATION`.
  final NotificationActionConfig notification;

  /// The template the GENERATE_PDF action renders (SERVICE_TASK only). Must be
  /// one of the templates linked to an earlier USER_TASK stage, else the
  /// run-time generation finds no `document_instance`.
  final int? generatePdfTemplateId;

  /// True when this stage already has a saved `stage_config` (complete-mode:
  /// the wizard opened an existing process). Locked stages are read-only and
  /// are NOT re-submitted — the backend rejects re-creating an existing config.
  final bool locked;

  const StageConfigDraft({
    required this.stage,
    this.assigneeType = AssigneeType.employee,
    this.assignments = const [],
    this.organizationId,
    this.departmentId,
    this.roleId,
    this.widgets = const [],
    this.requiresSignature = true,
    this.isAssignment = false,
    this.templateIds = const [],
    this.actions = const [],
    this.notification = const NotificationActionConfig(),
    this.generatePdfTemplateId,
    this.locked = false,
  });

  /// Whether SEND_NOTIFICATION is selected on this stage.
  bool get hasNotification => actions.contains('SEND_NOTIFICATION');

  /// Whether GENERATE_PDF is selected on this stage.
  bool get hasGeneratePdf => actions.contains('GENERATE_PDF');

  /// Whether the picker row currently holds a complete, addable triple.
  bool get canAddAssignment =>
      organizationId != null && departmentId != null && roleId != null;

  /// A USER_TASK is ready when at least one org/dept/role target has been added
  /// (the backend rejects a USER_TASK with no assignments). A SERVICE_TASK is
  /// ready unless an enabled action is missing required config: a
  /// SEND_NOTIFICATION with no message/recipient, or a GENERATE_PDF with no
  /// template (both rejected by the backend).
  bool get isComplete {
    // Already-saved stages are complete by definition (and not re-submitted).
    if (locked) return true;
    if (stage.isUserTask) {
      // A citizen assignee needs no org/dept/role — it ships an all-null entry.
      if (assigneeType == AssigneeType.citizen) return true;
      // Everything else (including dynamic routing) needs a real target: the
      // employees who execute THIS stage. `is_assignment` only decides where
      // the NEXT stage goes, so it never removes that requirement.
      return assignments.isNotEmpty;
    }
    if (hasNotification && !notification.isComplete) {
      return false;
    }
    if (hasGeneratePdf && generatePdfTemplateId == null) {
      return false;
    }
    return true;
  }

  StageConfigDraft copyWith({
    AssigneeType? assigneeType,
    List<StageAssignmentTarget>? assignments,
    int? organizationId,
    int? departmentId,
    int? roleId,
    bool clearDepartment = false,
    bool clearRole = false,
    List<WidgetConfig>? widgets,
    bool? requiresSignature,
    bool? isAssignment,
    List<int>? templateIds,
    List<String>? actions,
    NotificationActionConfig? notification,
    int? generatePdfTemplateId,
    bool clearGeneratePdfTemplate = false,
    bool? locked,
  }) {
    return StageConfigDraft(
      stage: stage,
      assigneeType: assigneeType ?? this.assigneeType,
      assignments: assignments ?? this.assignments,
      organizationId: organizationId ?? this.organizationId,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      roleId: clearRole ? null : (roleId ?? this.roleId),
      widgets: widgets ?? this.widgets,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      isAssignment: isAssignment ?? this.isAssignment,
      templateIds: templateIds ?? this.templateIds,
      actions: actions ?? this.actions,
      notification: notification ?? this.notification,
      generatePdfTemplateId: clearGeneratePdfTemplate
          ? null
          : (generatePdfTemplateId ?? this.generatePdfTemplateId),
      locked: locked ?? this.locked,
    );
  }

  /// Builds the `stages[]` entry for `POST /api/stage_config/create`.
  Map<String, dynamic> toRequestJson() {
    final configJson = <String, dynamic>{
      'form_id': stage.code,
      // The stage name (no separate input). `displayName` falls back to a
      // generated label for unnamed BPMN elements — the backend requires a
      // non-empty `form_name` and would 400 the whole batch otherwise.
      'form_name': stage.displayName,
      'widgets': stage.isUserTask
          ? widgets.map((w) => w.toJson()).toList()
          : <Map<String, dynamic>>[],
      // USER_TASK links templates ({ template_id }); SERVICE_TASK has none.
      'template': stage.isUserTask
          ? templateIds.map((id) => {'template_id': id}).toList()
          : <Map<String, dynamic>>[],
    };

    if (stage.isUserTask) {
      configJson['requires_digital_signature'] = requiresSignature;
      configJson['is_assignment'] = isAssignment;
    }

    if (stage.isServiceTask && actions.isNotEmpty) {
      configJson['actions'] = actions
          .map((name) => {'name': name, 'payload': _payloadFor(name)})
          .toList();
    }

    final entry = <String, dynamic>{
      'stage_id': stage.id,
      'config_json': configJson,
    };

    if (stage.isUserTask) {
      // An all-null entry is NOT "unassigned" — the backend reads it as the
      // CITIZEN role, so it is reserved for a citizen assignee only.
      //
      // `is_assignment` answers a DIFFERENT question: it controls where the
      // NEXT stage goes (picked at run-time by whoever works this stage), and
      // says nothing about who executes THIS stage. This stage still needs real
      // employee targets, and the backend rejects the CITIZEN shape when the
      // flag is on — a citizen cannot route transactions.
      if (assigneeType == AssigneeType.citizen) {
        entry['assignments'] = [const StageAssignmentTarget.citizen().toJson()];
      } else {
        // Employee assignee → every added org/dept/role target. The backend
        // creates one stage_assignments row per entry, so all matching
        // employees see the task.
        entry['assignments'] =
            assignments.map((a) => a.toJson()).toList();
      }
    }

    return entry;
  }

  /// The `payload` for a given action name. SEND_NOTIFICATION carries the
  /// message + recipient; GENERATE_PDF carries the template_id. Any other name
  /// falls back to an empty payload.
  Map<String, dynamic> _payloadFor(String name) {
    if (name == 'SEND_NOTIFICATION') {
      return notification.toPayloadJson();
    }
    if (name == 'GENERATE_PDF') {
      return generatePdfTemplateId == null
          ? <String, dynamic>{}
          : {'template_id': generatePdfTemplateId};
    }
    return <String, dynamic>{};
  }

  @override
  List<Object?> get props => [
        stage,
        assigneeType,
        assignments,
        organizationId,
        departmentId,
        roleId,
        widgets,
        requiresSignature,
        isAssignment,
        templateIds,
        actions,
        notification,
        generatePdfTemplateId,
        locked,
      ];
}
