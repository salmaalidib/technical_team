import 'package:equatable/equatable.dart';

/// Who receives a `SEND_NOTIFICATION` action.
///
/// * [citizen] → the transaction owner. The backend resolves this via
///   `to_camunda_group_key = "AUTH"`; no org/dept/role needed.
/// * [employee] → a specific role. The backend requires the full triple
///   `(organization_id, department_id, role_id)` together.
enum NotificationRecipient { citizen, employee }

/// Configuration for a `SEND_NOTIFICATION` service-task action.
///
/// The backend (`stageConfigSchema.js`) requires a `message` plus a recipient:
/// either `to_camunda_group_key="AUTH"` (citizen / transaction owner) OR the
/// full `(organization_id, department_id, role_id)` triple (employee role).
class NotificationActionConfig extends Equatable {
  /// The notification body (backend: required, 1..2000 chars).
  final String message;

  /// The notification title (backend: optional; defaults server-side).
  final String title;

  final NotificationRecipient recipient;

  /// Employee-recipient role cascade (only when [recipient] == employee).
  final int? organizationId;
  final int? departmentId;
  final int? roleId;

  const NotificationActionConfig({
    this.message = '',
    this.title = '',
    this.recipient = NotificationRecipient.citizen,
    this.organizationId,
    this.departmentId,
    this.roleId,
  });

  /// A citizen recipient needs only a message; an employee recipient needs the
  /// full org/dept/role triple too. Mirrors the backend validation so the UI
  /// can block submit before the request is rejected.
  bool get isComplete {
    if (message.trim().isEmpty) return false;
    if (recipient == NotificationRecipient.employee) {
      return organizationId != null &&
          departmentId != null &&
          roleId != null;
    }
    return true;
  }

  NotificationActionConfig copyWith({
    String? message,
    String? title,
    NotificationRecipient? recipient,
    int? organizationId,
    int? departmentId,
    int? roleId,
    bool clearDepartment = false,
    bool clearRole = false,
  }) {
    return NotificationActionConfig(
      message: message ?? this.message,
      title: title ?? this.title,
      recipient: recipient ?? this.recipient,
      organizationId: organizationId ?? this.organizationId,
      departmentId:
          clearDepartment ? null : (departmentId ?? this.departmentId),
      roleId: clearRole ? null : (roleId ?? this.roleId),
    );
  }

  /// Builds the `payload` for the `SEND_NOTIFICATION` action.
  ///
  /// citizen → `{ message, title?, to_camunda_group_key: "AUTH" }`
  /// employee → `{ message, title?, organization_id, department_id, role_id }`
  Map<String, dynamic> toPayloadJson() {
    final payload = <String, dynamic>{'message': message.trim()};
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) {
      payload['title'] = trimmedTitle;
    }

    if (recipient == NotificationRecipient.employee) {
      payload['organization_id'] = organizationId;
      payload['department_id'] = departmentId;
      payload['role_id'] = roleId;
    } else {
      payload['to_camunda_group_key'] = 'AUTH';
    }

    return payload;
  }

  @override
  List<Object?> get props =>
      [message, title, recipient, organizationId, departmentId, roleId];
}
