import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../../institutions/domain/entities/institution.dart';
import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_by_department.dart';

class RolesState extends Equatable {
  /// Roles list load.
  final RequestStatus status;
  final List<RoleAssignment> roles;
  final String? error;

  /// Organizations used by the create form (from the institutions feature).
  final List<Institution> organizations;

  /// Create-role form submission.
  final FormStatus formStatus;
  final String? formError;

  /// Department dropdown inside the create form: the leaves of [leafOrgId].
  final RequestStatus leafStatus;
  final List<LeafDepartment> leafDepartments;
  final int? leafOrgId;

  /// Roles of a single (leaf) department: `GET /api/role/by-department/{id}`.
  final RequestStatus byDeptStatus;
  final List<RoleByDepartment> rolesByDepartment;
  final int? byDeptId;

  /// Ids whose status toggle is in flight.
  final Set<int> togglingIds;

  /// One-shot message for action errors (toggle), surfaced as a snackbar.
  final String? actionError;

  const RolesState({
    this.status = RequestStatus.initial,
    this.roles = const [],
    this.error,
    this.organizations = const [],
    this.formStatus = FormStatus.idle,
    this.formError,
    this.leafStatus = RequestStatus.initial,
    this.leafDepartments = const [],
    this.leafOrgId,
    this.byDeptStatus = RequestStatus.initial,
    this.rolesByDepartment = const [],
    this.byDeptId,
    this.togglingIds = const {},
    this.actionError,
  });

  RolesState copyWith({
    RequestStatus? status,
    List<RoleAssignment>? roles,
    String? error,
    List<Institution>? organizations,
    FormStatus? formStatus,
    String? formError,
    RequestStatus? leafStatus,
    List<LeafDepartment>? leafDepartments,
    int? leafOrgId,
    RequestStatus? byDeptStatus,
    List<RoleByDepartment>? rolesByDepartment,
    int? byDeptId,
    Set<int>? togglingIds,
    String? actionError,
  }) {
    return RolesState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      error: error,
      organizations: organizations ?? this.organizations,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      leafStatus: leafStatus ?? this.leafStatus,
      leafDepartments: leafDepartments ?? this.leafDepartments,
      leafOrgId: leafOrgId ?? this.leafOrgId,
      byDeptStatus: byDeptStatus ?? this.byDeptStatus,
      rolesByDepartment: rolesByDepartment ?? this.rolesByDepartment,
      byDeptId: byDeptId ?? this.byDeptId,
      togglingIds: togglingIds ?? this.togglingIds,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roles,
        error,
        organizations,
        formStatus,
        formError,
        leafStatus,
        leafDepartments,
        leafOrgId,
        byDeptStatus,
        rolesByDepartment,
        byDeptId,
        togglingIds,
        actionError,
      ];
}
