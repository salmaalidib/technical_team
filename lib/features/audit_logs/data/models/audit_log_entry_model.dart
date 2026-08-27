import '../../domain/entities/audit_log_actor.dart';
import '../../domain/entities/audit_log_entry.dart';

/// يفكّ عنصر سجل تدقيق واحد من `data.items[]`.
class AuditLogEntryModel {
  const AuditLogEntryModel._();

  static AuditLogEntry fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: _int(json['id']) ?? 0,
      userId: _int(json['user_id']),
      action: json['action']?.toString() ?? '',
      resourceType: _nullableString(json['resource_type']),
      resourceId: _nullableString(json['resource_id']),
      status: AuditLogStatus.fromCode(json['status']?.toString()),
      ipAddress: _nullableString(json['ip_address']),
      userAgent: _nullableString(json['user_agent']),
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'] as Map)
          : const {},
      createdAt: _date(json['created_at']),
      user: _actor(json['user']),
    );
  }

  static AuditLogActor? _actor(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = _int(map['id']);
    if (id == null) return null;

    return AuditLogActor(
      id: id,
      userName: map['userName']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// يحوّل '' إلى null كي تعرض الواجهة شرطة بدل خانة فارغة غامضة.
  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// الخادم يرسل ISO-8601 بتوقيت UTC؛ نحوّله إلى التوقيت المحلي للعرض.
  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
