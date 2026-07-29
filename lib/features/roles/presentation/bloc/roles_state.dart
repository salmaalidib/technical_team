import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_by_department.dart';

class RolesState extends Equatable {
  /// Roles list load.
  final RequestStatus status;
  final List<RoleAssignment> roles;
  final String? error;

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

  /// All permissions in the system: the create form's checkbox options.
  final RequestStatus permissionsStatus;
  final List<Permission> permissions;

  /// Set when the role was created but attaching its permissions failed.
  /// The role exists, so the dialog closes and this is surfaced as a warning
  /// rather than a failure — retrying would only hit a 409 duplicate.
  final String? partialWarning;

  /// Edit-permissions dialog: loading the role's current permissions to
  /// pre-check the boxes.
  final RequestStatus editPermsStatus;

  /// The permission ids the role already has when the edit dialog opens.
  final Set<int> editInitialIds;

  /// Submission of the edited permission set (PUT replace).
  final FormStatus editFormStatus;
  final String? editFormError;

  /// Ids whose status toggle is in flight.
  final Set<int> togglingIds;

  /// One-shot message for action errors (toggle), surfaced as a snackbar.
  final String? actionError;

  const RolesState({
    this.status = RequestStatus.initial,
    this.roles = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.leafStatus = RequestStatus.initial,
    this.leafDepartments = const [],
    this.leafOrgId,
    this.byDeptStatus = RequestStatus.initial,
    this.rolesByDepartment = const [],
    this.byDeptId,
    this.permissionsStatus = RequestStatus.initial,
    this.permissions = const [],
    this.partialWarning,
    this.editPermsStatus = RequestStatus.initial,
    this.editInitialIds = const {},
    this.editFormStatus = FormStatus.idle,
    this.editFormError,
    this.togglingIds = const {},
    this.actionError,
  });

  RolesState copyWith({
    RequestStatus? status,
    List<RoleAssignment>? roles,
    String? error,
    FormStatus? formStatus,
    String? formError,
    RequestStatus? leafStatus,
    List<LeafDepartment>? leafDepartments,
    int? leafOrgId,
    RequestStatus? byDeptStatus,
    List<RoleByDepartment>? rolesByDepartment,
    int? byDeptId,
    RequestStatus? permissionsStatus,
    List<Permission>? permissions,
    String? partialWarning,
    RequestStatus? editPermsStatus,
    Set<int>? editInitialIds,
    FormStatus? editFormStatus,
    String? editFormError,
    Set<int>? togglingIds,
    String? actionError,
  }) {
    return RolesState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      leafStatus: leafStatus ?? this.leafStatus,
      leafDepartments: leafDepartments ?? this.leafDepartments,
      leafOrgId: leafOrgId ?? this.leafOrgId,
      byDeptStatus: byDeptStatus ?? this.byDeptStatus,
      rolesByDepartment: rolesByDepartment ?? this.rolesByDepartment,
      byDeptId: byDeptId ?? this.byDeptId,
      permissionsStatus: permissionsStatus ?? this.permissionsStatus,
      permissions: permissions ?? this.permissions,
      // One-shot, like actionError: cleared unless explicitly re-supplied.
      partialWarning: partialWarning,
      editPermsStatus: editPermsStatus ?? this.editPermsStatus,
      editInitialIds: editInitialIds ?? this.editInitialIds,
      editFormStatus: editFormStatus ?? this.editFormStatus,
      editFormError: editFormError,
      togglingIds: togglingIds ?? this.togglingIds,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roles,
        error,
        formStatus,
        formError,
        leafStatus,
        leafDepartments,
        leafOrgId,
        byDeptStatus,
        rolesByDepartment,
        byDeptId,
        permissionsStatus,
        permissions,
        partialWarning,
        editPermsStatus,
        editInitialIds,
        editFormStatus,
        editFormError,
        togglingIds,
        actionError,
      ];
}
