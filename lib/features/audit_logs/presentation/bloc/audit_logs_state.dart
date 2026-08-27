import 'package:equatable/equatable.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_log_filter.dart';

class AuditLogsState extends Equatable {
  /// حالة تحميل الصفحة الأولى — هي وحدها التي تُظهر الهيكل العظمي.
  final RequestStatus status;
  final List<AuditLogEntry> items;
  final String? error;

  /// الفلاتر المطبَّقة حالياً؛ تُعاد مع كل طلب صفحة تالية.
  final AuditLogFilter filter;

  /// ترقيم cursor: `nextCursor` هو مفتاح الصفحة التالية و`hasNext` شرط عرض
  /// زرّ «تحميل المزيد».
  final String? nextCursor;
  final bool hasNext;
  final int limit;

  /// أكواد الأحداث القادمة من الخادم — تملأ قائمة فلتر «الحدث».
  ///
  /// تُحدَّث فقط حين يعيد الخادم قائمة غير فارغة: استجابة مفلترة تعيد أكواد
  /// النتائج الظاهرة وحدها، ولو استبدلناها لتقلّصت خيارات الفلترة بعد كل بحث.
  final List<String> knownActions;

  /// تحميل الصفحة التالية — مؤشّر أسفل الجدول لا هيكل كامل.
  final bool isLoadingMore;

  /// خطأ في تحميل المزيد؛ snackbar لا يمسح الصفوف المعروضة.
  final String? loadMoreError;

  const AuditLogsState({
    this.status = RequestStatus.initial,
    this.items = const [],
    this.error,
    this.filter = const AuditLogFilter(),
    this.nextCursor,
    this.hasNext = false,
    this.limit = 20,
    this.knownActions = const [],
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get isEmpty => status == RequestStatus.success && items.isEmpty;

  AuditLogsState copyWith({
    RequestStatus? status,
    List<AuditLogEntry>? items,
    String? error,
    bool clearError = false,
    AuditLogFilter? filter,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasNext,
    int? limit,
    List<String>? knownActions,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return AuditLogsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasNext: hasNext ?? this.hasNext,
      limit: limit ?? this.limit,
      knownActions: knownActions ?? this.knownActions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        error,
        filter,
        nextCursor,
        hasNext,
        limit,
        knownActions,
        isLoadingMore,
        loadMoreError,
      ];
}
