import '../../domain/entities/role_permissions.dart';
import 'permission_model.dart';

class RolePermissionsModel extends RolePermissions {
  const RolePermissionsModel({
    required super.orgDeptRoleId,
    required super.organizationId,
    required super.departmentId,
    required super.roleId,
    super.permissions,
  });

  factory RolePermissionsModel.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];

    return RolePermissionsModel(
      orgDeptRoleId: (json['organization_department_roles_id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      departmentId: (json['department_id'] ?? 0) as int,
      roleId: (json['role_id'] ?? 0) as int,
      permissions: rawPermissions is List
          ? rawPermissions
              .whereType<Map<String, dynamic>>()
              .map(PermissionModel.fromJson)
              .toList()
          : const [],
    );
  }
}
