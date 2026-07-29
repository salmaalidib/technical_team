import 'package:equatable/equatable.dart';

import 'permission.dart';

/// The permissions attached to one `organization_department_roles` row, as
/// returned by `GET /api/auth/role-permissions`.
///
/// Permissions hang off the (organization, department, role) triple — not off
/// the role alone — so the same role can carry different permissions in a
/// different organization or department.
class RolePermissions extends Equatable {
  /// Id of the resolved `organization_department_roles` row.
  final int orgDeptRoleId;
  final int organizationId;
  final int departmentId;

  /// Id of the `roles` row (NOT the org-dept-role link id).
  final int roleId;

  final List<Permission> permissions;

  const RolePermissions({
    required this.orgDeptRoleId,
    required this.organizationId,
    required this.departmentId,
    required this.roleId,
    this.permissions = const [],
  });

  /// Ids only — what the create/update endpoints expect as `permission_id`.
  List<int> get permissionIds => permissions.map((p) => p.id).toList();

  @override
  List<Object?> get props => [
        orgDeptRoleId,
        organizationId,
        departmentId,
        roleId,
        permissions,
      ];
}
