import 'package:equatable/equatable.dart';

/// Pagination metadata returned by the backend list endpoints under
/// `data.pagination` — e.g.
/// `{ page, limit, total, total_pages, has_next, has_prev }`.
class PageMeta extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PageMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  static int _int(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _bool(dynamic v) => v == true || v == 'true' || v == 1;

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    final page = _int(json['page'], 1);
    final limit = _int(json['limit'], 0);
    final total = _int(json['total'], 0);
    final totalPages =
        _int(json['total_pages'] ?? json['totalPages'], limit > 0 ? 1 : 0);
    return PageMeta(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: json.containsKey('has_next') || json.containsKey('hasNext')
          ? _bool(json['has_next'] ?? json['hasNext'])
          : page < totalPages,
      hasPrev: json.containsKey('has_prev') || json.containsKey('hasPrev')
          ? _bool(json['has_prev'] ?? json['hasPrev'])
          : page > 1,
    );
  }

  /// An empty first-page meta (used before any load / for empty results).
  static const empty = PageMeta(
    page: 1,
    limit: 0,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  );

  @override
  List<Object?> get props =>
      [page, limit, total, totalPages, hasNext, hasPrev];
}

/// A page of [items] plus its [meta]. Returned by paginated list use-cases.
class Paginated<T> extends Equatable {
  final List<T> items;
  final PageMeta meta;

  const Paginated({required this.items, required this.meta});

  @override
  List<Object?> get props => [items, meta];
}
