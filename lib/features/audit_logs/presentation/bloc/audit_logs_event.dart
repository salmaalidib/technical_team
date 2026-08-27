import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_log_filter.dart';

abstract class AuditLogsEvent extends Equatable {
  const AuditLogsEvent();

  @override
  List<Object?> get props => [];
}

/// أول تحميل للشاشة — الصفحة الأولى بالفلاتر الحالية.
class LoadAuditLogs extends AuditLogsEvent {
  const LoadAuditLogs();
}

/// يجلب الصفحة التالية عبر `next_cursor` ويُلحقها بالقائمة الحالية.
class LoadMoreAuditLogs extends AuditLogsEvent {
  const LoadMoreAuditLogs();
}

/// يستبدل الفلاتر بالكامل ويعيد التحميل من الصفحة الأولى.
class ApplyAuditLogFilter extends AuditLogsEvent {
  final AuditLogFilter filter;
  const ApplyAuditLogFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// يمسح كل الفلاتر ويعيد التحميل.
class ClearAuditLogFilter extends AuditLogsEvent {
  const ClearAuditLogFilter();
}

/// فلترة سريعة بالحالة من شرائح أعلى الجدول.
class FilterByStatus extends AuditLogsEvent {
  /// `null` = كل الحالات.
  final AuditLogStatus? status;
  const FilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// إعادة تحميل بنفس الفلاتر (زر التحديث).
class RefreshAuditLogs extends AuditLogsEvent {
  const RefreshAuditLogs();
}

/// يغيّر حجم الصفحة ويعيد التحميل من البداية.
class ChangeAuditLogsLimit extends AuditLogsEvent {
  final int limit;
  const ChangeAuditLogsLimit(this.limit);

  @override
  List<Object?> get props => [limit];
}
