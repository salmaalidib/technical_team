import 'package:equatable/equatable.dart';

import 'audit_log_entry.dart';

/// صفحة سجلات تدقيق بترقيم **cursor** (لا أرقام صفحات): الخادم يعيد
/// `pagination.next_cursor` نمرّره كما هو لجلب الصفحة التالية، والترتيب دائماً
/// `created_at DESC, id DESC`.
class AuditLogsPage extends Equatable {
  final List<AuditLogEntry> items;

  /// يُمرَّر كـ `?cursor=` لجلب ما بعد هذه الصفحة. `null` يعني لا مزيد.
  final String? nextCursor;
  final bool hasNext;
  final int limit;

  /// أكواد الأحداث المعروفة في الخادم — تملأ قائمة فلتر «الحدث» بدل قائمة
  /// مكتوبة يدوياً في العميل تتقادم مع كل حدث جديد يُضاف في الخادم.
  final List<String> knownActions;

  const AuditLogsPage({
    this.items = const [],
    this.nextCursor,
    this.hasNext = false,
    this.limit = 20,
    this.knownActions = const [],
  });

  @override
  List<Object?> get props => [items, nextCursor, hasNext, limit, knownActions];
}
