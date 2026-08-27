import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/entities/audit_log_filter.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import 'audit_logs_event.dart';
import 'audit_logs_state.dart';

/// يقود شاشة سجلات التدقيق: تحميل أول صفحة، الفلترة، والتقدّم عبر الـ cursor.
class AuditLogsBloc extends Bloc<AuditLogsEvent, AuditLogsState> {
  final GetAuditLogsUseCase getAuditLogs;

  AuditLogsBloc({required this.getAuditLogs}) : super(const AuditLogsState()) {
    on<LoadAuditLogs>(_onLoad);
    on<RefreshAuditLogs>(_onRefresh);
    on<LoadMoreAuditLogs>(_onLoadMore);
    on<ApplyAuditLogFilter>(_onApplyFilter);
    on<ClearAuditLogFilter>(_onClearFilter);
    on<FilterByStatus>(_onFilterByStatus);
    on<ChangeAuditLogsLimit>(_onChangeLimit);
  }

  Future<void> _onLoad(
    LoadAuditLogs event,
    Emitter<AuditLogsState> emit,
  ) =>
      _fetchFirstPage(emit);

  Future<void> _onRefresh(
    RefreshAuditLogs event,
    Emitter<AuditLogsState> emit,
  ) =>
      _fetchFirstPage(emit);

  Future<void> _onApplyFilter(
    ApplyAuditLogFilter event,
    Emitter<AuditLogsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
    return _fetchFirstPage(emit);
  }

  Future<void> _onClearFilter(
    ClearAuditLogFilter event,
    Emitter<AuditLogsState> emit,
  ) {
    emit(state.copyWith(filter: const AuditLogFilter()));
    return _fetchFirstPage(emit);
  }

  Future<void> _onFilterByStatus(
    FilterByStatus event,
    Emitter<AuditLogsState> emit,
  ) {
    final filter = event.status == null
        ? state.filter.copyWith(clearStatus: true)
        : state.filter.copyWith(status: event.status);

    emit(state.copyWith(filter: filter));
    return _fetchFirstPage(emit);
  }

  Future<void> _onChangeLimit(
    ChangeAuditLogsLimit event,
    Emitter<AuditLogsState> emit,
  ) {
    if (event.limit == state.limit) return Future.value();
    emit(state.copyWith(limit: event.limit));
    return _fetchFirstPage(emit);
  }

  /// تحميل من الصفر: يمسح الـ cursor لأن أي cursor قديم يعود لفلترة سابقة
  /// ويرفضه الخادم أو يعيد نتائج لا تطابق الفلاتر الجديدة.
  Future<void> _fetchFirstPage(Emitter<AuditLogsState> emit) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      clearError: true,
      clearLoadMoreError: true,
      isLoadingMore: false,
    ));

    final result = await getAuditLogs(
      filter: state.filter,
      limit: state.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: RequestStatus.success,
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasNext: page.hasNext,
        // قائمة الأحداث تُحدَّث فقط حين يعيدها الخادم غير فارغة؛ استجابة
        // مفلترة تعيد أكواد النتائج الظاهرة وحدها فلا تصلح كقائمة خيارات.
        knownActions: page.knownActions.isNotEmpty
            ? page.knownActions
            : state.knownActions,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreAuditLogs event,
    Emitter<AuditLogsState> emit,
  ) async {
    final cursor = state.nextCursor;
    // حارس مزدوج: لا مزيد من الصفحات، أو طلب جارٍ بالفعل (نقرة مكرّرة على
    // الزر كانت ستُلحق نفس الصفحة مرّتين).
    if (cursor == null || !state.hasNext || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await getAuditLogs(
      filter: state.filter,
      cursor: cursor,
      limit: state.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        loadMoreError: failure.message,
      )),
      (page) => emit(state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasNext: page.hasNext,
        knownActions: page.knownActions.isNotEmpty
            ? page.knownActions
            : state.knownActions,
      )),
    );
  }
}
