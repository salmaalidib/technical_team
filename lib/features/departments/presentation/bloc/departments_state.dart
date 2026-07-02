import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_overview.dart';

/// One hop in the drill-down trail (root → parent → sub-section …).
class DepartmentCrumb extends Equatable {
  final int id;
  final String name;

  const DepartmentCrumb({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class DepartmentsState extends Equatable {
  final RequestStatus status;

  /// The full, flat list of departments across every level. The visible level
  /// is derived from it via [levelDepartments] using [currentParentId].
  final List<Department> departments;
  final String? error;

  /// Create-department form submission.
  final FormStatus formStatus;
  final String? formError;

  /// Per-department overview cache + the ids whose overview is in flight.
  final Map<int, DepartmentOverview> overviews;
  final Set<int> loadingOverviews;

  /// Ids whose status toggle is in flight.
  final Set<int> togglingIds;

  /// One-shot message for action errors (toggle / overview), surfaced as a
  /// snackbar by the page.
  final String? actionError;

  /// Drill-down trail. Empty == root level (top-level departments).
  final List<DepartmentCrumb> breadcrumb;

  /// Client-side search within the current level.
  final String searchQuery;

  /// Client-side pagination (1-based) of the current level.
  final int currentPage;
  final int pageSize;

  const DepartmentsState({
    this.status = RequestStatus.initial,
    this.departments = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.overviews = const {},
    this.loadingOverviews = const {},
    this.togglingIds = const {},
    this.actionError,
    this.breadcrumb = const [],
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 10,
  });

  /// The parent whose children are currently shown, or null at root.
  int? get currentParentId =>
      breadcrumb.isEmpty ? null : breadcrumb.last.id;

  /// Departments belonging to the current level, after search filtering.
  List<Department> get levelDepartments {
    final parentId = currentParentId;
    final query = searchQuery.trim();
    return departments.where((d) {
      if (d.parentId != parentId) return false;
      if (query.isEmpty) return true;
      return d.name.contains(query);
    }).toList();
  }

  int get pageCount {
    final total = levelDepartments.length;
    if (total == 0) return 1;
    return (total / pageSize).ceil();
  }

  /// The slice of [levelDepartments] for [currentPage].
  List<Department> get pagedDepartments {
    final level = levelDepartments;
    final start = (currentPage - 1) * pageSize;
    if (start >= level.length) return const [];
    final end = (start + pageSize).clamp(0, level.length);
    return level.sublist(start, end);
  }

  DepartmentsState copyWith({
    RequestStatus? status,
    List<Department>? departments,
    String? error,
    FormStatus? formStatus,
    String? formError,
    Map<int, DepartmentOverview>? overviews,
    Set<int>? loadingOverviews,
    Set<int>? togglingIds,
    String? actionError,
    List<DepartmentCrumb>? breadcrumb,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
  }) {
    return DepartmentsState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      overviews: overviews ?? this.overviews,
      loadingOverviews: loadingOverviews ?? this.loadingOverviews,
      togglingIds: togglingIds ?? this.togglingIds,
      actionError: actionError,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        status,
        departments,
        error,
        formStatus,
        formError,
        overviews,
        loadingOverviews,
        togglingIds,
        actionError,
        breadcrumb,
        searchQuery,
        currentPage,
        pageSize,
      ];
}
