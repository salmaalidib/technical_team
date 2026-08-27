import 'package:equatable/equatable.dart';

import 'audit_log_entry.dart';

/// مجموعة الفلاتر المدعومة في `GET /api/auth/audit-logs`.
///
/// كل الحقول اختيارية وقابلة للدمج. تُحفظ كقيمة واحدة في حالة الـ bloc حتى
/// تُعاد مع كل طلب صفحة تالية — وإلا لجاءت الصفحة الثانية غير مفلترة.
class AuditLogFilter extends Equatable {
  final int? userId;
  final String? action;
  final AuditLogStatus? status;
  final String? resourceType;

  /// بداية/نهاية الفترة. تُرسَل بصيغة `YYYY-MM-DD` وهي شاملة للطرفين.
  final DateTime? fromDate;
  final DateTime? toDate;

  const AuditLogFilter({
    this.userId,
    this.action,
    this.status,
    this.resourceType,
    this.fromDate,
    this.toDate,
  });

  bool get isEmpty =>
      userId == null &&
      (action == null || action!.isEmpty) &&
      status == null &&
      (resourceType == null || resourceType!.isEmpty) &&
      fromDate == null &&
      toDate == null;

  /// عدد الفلاتر الفعّالة — يُعرض كشارة على زرّ الفلترة.
  int get activeCount => [
        userId,
        (action?.isNotEmpty ?? false) ? action : null,
        status,
        (resourceType?.isNotEmpty ?? false) ? resourceType : null,
        fromDate,
        toDate,
      ].where((v) => v != null).length;

  /// `clearX` ضرورية لأن `copyWith(userId: null)` لا يمكنه التمييز بين
  /// «لا تغيّر» و«امسح القيمة».
  AuditLogFilter copyWith({
    int? userId,
    bool clearUserId = false,
    String? action,
    bool clearAction = false,
    AuditLogStatus? status,
    bool clearStatus = false,
    String? resourceType,
    bool clearResourceType = false,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
  }) {
    return AuditLogFilter(
      userId: clearUserId ? null : (userId ?? this.userId),
      action: clearAction ? null : (action ?? this.action),
      status: clearStatus ? null : (status ?? this.status),
      resourceType:
          clearResourceType ? null : (resourceType ?? this.resourceType),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  @override
  List<Object?> get props =>
      [userId, action, status, resourceType, fromDate, toDate];
}
