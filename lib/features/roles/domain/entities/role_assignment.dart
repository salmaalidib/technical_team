import 'package:equatable/equatable.dart';

/// A role assignment as returned by `GET /api/role` — one row of
/// `organization_department_roles` joined with its role / organization /
/// department relations.
///
/// [id] is the assignment (link) id, used for toggling the status.
class RoleAssignment extends Equatable {
  final int id;

  /// Id of the `roles` row — distinct from [id], which is the link id.
  /// The permission endpoints key off this one, not off [id].
  final int roleId;

  final String roleName;
  final String roleCode;
  final int organizationId;
  final String? organizationName;
  final int departmentId;
  final String? departmentName;

  /// Link id of the parent assignment (`organization_department_roles.parent_id`).
  /// Null for a root role — one with no role above it in the hierarchy.
  final int? parentId;

  /// Role name of the parent assignment, when the response embeds the relation.
  final String? parentRoleName;

  /// Server-generated group key: `CODE__ORG{X}__DEPT{Y}`.
  final String? camundaGroupKey;
  final bool isActive;

  const RoleAssignment({
    required this.id,
    this.roleId = 0,
    required this.roleName,
    required this.roleCode,
    required this.organizationId,
    this.organizationName,
    required this.departmentId,
    this.departmentName,
    this.parentId,
    this.parentRoleName,
    this.camundaGroupKey,
    this.isActive = true,
  });

  RoleAssignment copyWith({bool? isActive}) {
    return RoleAssignment(
      id: id,
      roleId: roleId,
      roleName: roleName,
      roleCode: roleCode,
      organizationId: organizationId,
      organizationName: organizationName,
      departmentId: departmentId,
      departmentName: departmentName,
      parentId: parentId,
      parentRoleName: parentRoleName,
      camundaGroupKey: camundaGroupKey,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roleId,
        roleName,
        roleCode,
        organizationId,
        organizationName,
        departmentId,
        departmentName,
        parentId,
        parentRoleName,
        camundaGroupKey,
        isActive,
      ];
}
