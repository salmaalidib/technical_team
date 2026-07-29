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
    super.camundaGroupKey,
    super.isActive,
  });

  factory RoleAssignmentModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final organization = json['organization'];
    final department = json['department'];

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
      camundaGroupKey: json['camunda_group_key'] as String?,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}
