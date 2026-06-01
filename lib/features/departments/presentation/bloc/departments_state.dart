import 'package:equatable/equatable.dart';

import '../../../institutions/domain/entities/institution.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_overview.dart';

enum DepartmentsStatus { initial, loading, success, failure }

enum DepartmentFormStatus { idle, submitting, success, failure }

class DepartmentsState extends Equatable {
  final DepartmentsStatus status;
  final List<Department> departments;
  final List<Institution> organizations;
  final String? error;

  /// Create-department form submission.
  final DepartmentFormStatus formStatus;
  final String? formError;

  /// Per-department overview cache + the ids whose overview is in flight.
  final Map<int, DepartmentOverview> overviews;
  final Set<int> loadingOverviews;

  /// Ids whose status toggle is in flight.
  final Set<int> togglingIds;

  /// One-shot message for action errors (toggle / overview), surfaced as a
  /// snackbar by the page.
  final String? actionError;

  const DepartmentsState({
    this.status = DepartmentsStatus.initial,
    this.departments = const [],
    this.organizations = const [],
    this.error,
    this.formStatus = DepartmentFormStatus.idle,
    this.formError,
    this.overviews = const {},
    this.loadingOverviews = const {},
    this.togglingIds = const {},
    this.actionError,
  });

  DepartmentsState copyWith({
    DepartmentsStatus? status,
    List<Department>? departments,
    List<Institution>? organizations,
    String? error,
    DepartmentFormStatus? formStatus,
    String? formError,
    Map<int, DepartmentOverview>? overviews,
    Set<int>? loadingOverviews,
    Set<int>? togglingIds,
    String? actionError,
  }) {
    return DepartmentsState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      organizations: organizations ?? this.organizations,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      overviews: overviews ?? this.overviews,
      loadingOverviews: loadingOverviews ?? this.loadingOverviews,
      togglingIds: togglingIds ?? this.togglingIds,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        departments,
        organizations,
        error,
        formStatus,
        formError,
        overviews,
        loadingOverviews,
        togglingIds,
        actionError,
      ];
}
