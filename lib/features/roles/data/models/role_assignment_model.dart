import '../../domain/entities/role_assignment.dart';

class RoleAssignmentModel extends RoleAssignment {
  const RoleAssignmentModel({
    required super.id,
    super.roleId,
    required super.roleName,
    required super.roleCode,
    required super.organizationId,
    super.organizationName,
    required super.departmentId,
    super.departmentName,
    super.parentId,
    super.parentRoleName,
    super.camundaGroupKey,
    super.isActive,
  });

  factory RoleAssignmentModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final organization = json['organization'];
    final department = json['department'];
    // The embedded `parent` summary carries ids only (no role name), so the
    // top-level `parent_id` is the reliable source and the name stays null
    // unless a response happens to embed the parent's role relation.
    final parent = json['parent'];

    return RoleAssignmentModel(
      id: json['id'] as int,
      // Top-level `role_id` is what the API returns; the nested `role.id` is a
      // fallback for responses that only embed the relation.
      roleId: (json['role_id'] ?? (role is Map ? role['id'] : null) ?? 0) as int,
      roleName: role is Map ? (role['name'] ?? '') as String : '',
      roleCode: role is Map ? (role['code'] ?? '') as String : '',
      organizationId: (json['organization_id'] ?? 0) as int,
      organizationName:
          organization is Map ? organization['name'] as String? : null,
      departmentId: (json['department_id'] ?? 0) as int,
      departmentName: department is Map ? department['name'] as String? : null,
      parentId:
          (json['parent_id'] ?? (parent is Map ? parent['id'] : null)) as int?,
      parentRoleName: parent is Map && parent['role'] is Map
          ? parent['role']['name'] as String?
          : null,
      camundaGroupKey: json['camunda_group_key'] as String?,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}
