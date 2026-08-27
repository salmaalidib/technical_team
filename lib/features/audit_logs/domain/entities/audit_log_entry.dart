import 'package:equatable/equatable.dart';

import 'audit_log_actor.dart';

/// حالة السجل كما يعرّفها الخادم: `success | failure | blocked`.
///
/// أي قيمة غير معروفة تسقط إلى [unknown] بدل رمي استثناء — سجلّ بحالة جديدة
/// أُضيفت في الخادم يجب أن يظهر في الجدول لا أن يُسقط الشاشة.
enum AuditLogStatus {
  success,
  failure,
  blocked,
  unknown;

  static AuditLogStatus fromCode(String? code) {
    switch (code) {
      case 'success':
        return AuditLogStatus.success;
      case 'failure':
        return AuditLogStatus.failure;
      case 'blocked':
        return AuditLogStatus.blocked;
      default:
        return AuditLogStatus.unknown;
    }
  }

  /// القيمة التي تُرسَل كـ `?status=`. `unknown` لا يُرسَل أبداً.
  String? get code => this == AuditLogStatus.unknown ? null : name;

  String get label {
    switch (this) {
      case AuditLogStatus.success:
        return 'ناجح';
      case AuditLogStatus.failure:
        return 'فاشل';
      case AuditLogStatus.blocked:
        return 'محظور';
      case AuditLogStatus.unknown:
        return 'غير معروف';
    }
  }
}

/// سجلّ تدقيق واحد من `GET /api/auth/audit-logs`.
class AuditLogEntry extends Equatable {
  final int id;
  final int? userId;

  /// كود الحدث التقني (مثل `TASK_PICKED_UP`) — يُستخدم كما هو في الفلترة.
  final String action;
  final String? resourceType;
  final String? resourceId;
  final AuditLogStatus status;
  final String? ipAddress;
  final String? userAgent;

  /// حمولة حرّة يختلف شكلها بحسب الحدث؛ تُعرض كـ JSON في تفاصيل السجل.
  final Map<String, dynamic> details;
  final DateTime? createdAt;
  final AuditLogActor? user;

  const AuditLogEntry({
    required this.id,
    this.userId,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.status = AuditLogStatus.unknown,
    this.ipAddress,
    this.userAgent,
    this.details = const {},
    this.createdAt,
    this.user,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        resourceType,
        resourceId,
        status,
        ipAddress,
        userAgent,
        details,
        createdAt,
        user,
      ];
}
