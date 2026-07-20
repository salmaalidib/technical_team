import 'package:equatable/equatable.dart';

import 'notification_action_config.dart';
import 'process_stage.dart';
import 'widget_config.dart';

/// Who executes a USER_TASK: a specific [employee] (org/dept/role cascade) or
/// the transaction owner [citizen] (no cascade — a fixed citizen role).
enum AssigneeType { employee, citizen }

/// The role_id sent for a citizen-assigned USER_TASK. The backend uses it as
/// the applicant/citizen role; org/dept are null in that case.
const int kCitizenRoleId = 2;

/// The in-progress customization of one stage (step 4). Converted to the
/// backend `stages[]` entry on submit.
///
/// USER_TASK → form (widgets) + assignment (org/dept/role) [+ signature].
/// SERVICE_TASK → optional [actions] (GENERATE_PDF / SEND_NOTIFICATION; the
/// backend does not support SEND_EMAIL).
class StageConfigDraft extends Equatable {
  final ProcessStage stage;

  /// Who executes this USER_TASK (employee cascade vs citizen). Defaults to
  /// [AssigneeType.employee] so existing behaviour is unchanged.
  final AssigneeType assigneeType;

  /// Assignment (USER_TASK only). For a citizen assignee these stay null and
  /// the request uses [kCitizenRoleId] as the role.
  final int? organizationId;
  final int? departmentId;
  final int? roleId;

  /// Selected field widgets (USER_TASK only), keyed by widgetId for dedup.
  final List<WidgetConfig> widgets;

  final bool requiresSignature;

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
    this.organizationId,
    this.departmentId,
    this.roleId,
    this.widgets = const [],
    this.requiresSignature = true,
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

  /// A USER_TASK is ready when an org/dept/role assignment is fully chosen
  /// (the backend rejects a USER_TASK with no assignments). A SERVICE_TASK is
  /// ready unless an enabled action is missing required config: a
  /// SEND_NOTIFICATION with no message/recipient, or a GENERATE_PDF with no
  /// template (both rejected by the backend).
  bool get isComplete {
    // Already-saved stages are complete by definition (and not re-submitted).
    if (locked) return true;
    if (stage.isUserTask) {
      // A citizen assignee needs no org/dept/role — it ships a fixed role.
      if (assigneeType == AssigneeType.citizen) return true;
      return organizationId != null &&
          departmentId != null &&
          roleId != null;
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
    int? organizationId,
    int? departmentId,
    int? roleId,
    bool clearDepartment = false,
    bool clearRole = false,
    List<WidgetConfig>? widgets,
    bool? requiresSignature,
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
      organizationId: organizationId ?? this.organizationId,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      roleId: clearRole ? null : (roleId ?? this.roleId),
      widgets: widgets ?? this.widgets,
      requiresSignature: requiresSignature ?? this.requiresSignature,
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
      'form_name': stage.name, // always the stage name (no separate input)
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
      // Citizen assignee → no org/dept, fixed citizen role. Employee assignee →
      // the picked org/dept/role cascade.
      final isCitizen = assigneeType == AssigneeType.citizen;
      entry['assignments'] = [
        {
          'organization_id': isCitizen ? null : organizationId,
          'department_id': isCitizen ? null : departmentId,
          'role_id': isCitizen ? kCitizenRoleId : roleId,
        }
      ];
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
        organizationId,
        departmentId,
        roleId,
        widgets,
        requiresSignature,
        templateIds,
        actions,
        notification,
        generatePdfTemplateId,
        locked,
      ];
}
