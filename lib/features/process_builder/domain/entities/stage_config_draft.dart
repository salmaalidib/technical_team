import 'package:equatable/equatable.dart';

import 'process_stage.dart';
import 'widget_config.dart';

/// The in-progress customization of one stage (step 4). Converted to the
/// backend `stages[]` entry on submit.
///
/// USER_TASK → form (widgets) + assignment (org/dept/role) [+ signature].
/// SERVICE_TASK → optional [actions] (GENERATE_PDF / SEND_EMAIL / SEND_NOTIFICATION).
class StageConfigDraft extends Equatable {
  final ProcessStage stage;

  /// Assignment (USER_TASK only).
  final int? organizationId;
  final int? departmentId;
  final int? roleId;

  /// Selected field widgets (USER_TASK only), keyed by widgetId for dedup.
  final List<WidgetConfig> widgets;

  final bool requiresSignature;

  /// Selected automatic actions (SERVICE_TASK only).
  final List<String> actions;

  const StageConfigDraft({
    required this.stage,
    this.organizationId,
    this.departmentId,
    this.roleId,
    this.widgets = const [],
    this.requiresSignature = false,
    this.actions = const [],
  });

  /// A USER_TASK is ready when an org/dept/role assignment is fully chosen
  /// (the backend rejects a USER_TASK with no assignments).
  bool get isComplete {
    if (stage.isUserTask) {
      return organizationId != null &&
          departmentId != null &&
          roleId != null;
    }
    return true; // SERVICE_TASK needs nothing mandatory
  }

  StageConfigDraft copyWith({
    int? organizationId,
    int? departmentId,
    int? roleId,
    bool clearDepartment = false,
    bool clearRole = false,
    List<WidgetConfig>? widgets,
    bool? requiresSignature,
    List<String>? actions,
  }) {
    return StageConfigDraft(
      stage: stage,
      organizationId: organizationId ?? this.organizationId,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      roleId: clearRole ? null : (roleId ?? this.roleId),
      widgets: widgets ?? this.widgets,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      actions: actions ?? this.actions,
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
      'template': <Map<String, dynamic>>[], // ربط القوالب — مؤجّل
    };

    if (stage.isUserTask) {
      configJson['requires_digital_signature'] = requiresSignature;
    }

    if (stage.isServiceTask && actions.isNotEmpty) {
      configJson['actions'] =
          actions.map((name) => {'name': name, 'payload': {}}).toList();
    }

    final entry = <String, dynamic>{
      'stage_id': stage.id,
      'config_json': configJson,
    };

    if (stage.isUserTask) {
      entry['assignments'] = [
        {
          'organization_id': organizationId,
          'department_id': departmentId,
          'role_id': roleId,
        }
      ];
    }

    return entry;
  }

  @override
  List<Object?> get props => [
        stage,
        organizationId,
        departmentId,
        roleId,
        widgets,
        requiresSignature,
        actions,
      ];
}
