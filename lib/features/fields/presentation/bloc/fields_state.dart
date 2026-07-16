import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
import '../../domain/entities/field_type.dart';

/// The paginated, searchable state of ONE field type's library. Each dynamic
/// dropdown (per type) reads its own [FieldTypeState] — items are already mapped
/// to [WidgetConfig] so both the stage picker and the template picker consume
/// the same shape.
class FieldTypeState extends Equatable {
  /// Accumulated items across the pages loaded so far (for infinite scroll).
  final List<WidgetConfig> items;

  /// Pagination metadata of the last loaded page (null before first load).
  final PageMeta? meta;

  /// The current search term driving the list (empty = no filter).
  final String search;

  /// Status of the first page / a fresh search.
  final RequestStatus status;

  /// True while appending the next page (bottom spinner), not a full reload.
  final bool loadingMore;

  final String? error;

  const FieldTypeState({
    this.items = const [],
    this.meta,
    this.search = '',
    this.status = RequestStatus.initial,
    this.loadingMore = false,
    this.error,
  });

  /// Whether another page can be fetched.
  bool get hasMore => meta?.hasNext ?? false;

  /// The page number to request next.
  int get nextPage => (meta?.page ?? 0) + 1;

  FieldTypeState copyWith({
    List<WidgetConfig>? items,
    PageMeta? meta,
    String? search,
    RequestStatus? status,
    bool? loadingMore,
    String? error,
  }) {
    return FieldTypeState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [items, meta, search, status, loadingMore, error];
}

/// Holds one [FieldTypeState] per [FieldType], plus the shared create-form state
/// used by the "+ create field" dialog.
class FieldsState extends Equatable {
  final Map<FieldType, FieldTypeState> byType;

  final FormStatus createStatus;
  final String? createError;

  const FieldsState({
    this.byType = const {},
    this.createStatus = FormStatus.idle,
    this.createError,
  });

  /// The (never-null) per-type state for [type].
  FieldTypeState of(FieldType type) =>
      byType[type] ?? const FieldTypeState();

  /// Returns a copy with [type]'s slice replaced by [state].
  FieldsState withType(FieldType type, FieldTypeState state) {
    return copyWith(byType: {...byType, type: state});
  }

  FieldsState copyWith({
    Map<FieldType, FieldTypeState>? byType,
    FormStatus? createStatus,
    String? createError,
  }) {
    return FieldsState(
      byType: byType ?? this.byType,
      createStatus: createStatus ?? this.createStatus,
      createError: createError,
    );
  }

  @override
  List<Object?> get props => [byType, createStatus, createError];
}
