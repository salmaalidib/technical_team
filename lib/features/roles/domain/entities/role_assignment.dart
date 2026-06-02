import 'package:equatable/equatable.dart';

/// A role assignment as returned by `GET /api/role` — one row of
/// `organization_department_roles` joined with its role / organization /
/// department relations.
///
/// [id] is the assignment (link) id, used for toggling the status.
class RoleAssignment extends Equatable {
  final int id;
  final String roleName;
  final String roleCode;
  final int organizationId;
  final String? organizationName;
  final int departmentId;
  final String? departmentName;

  /// Server-generated group key: `CODE__ORG{X}__DEPT{Y}`.
  final String? camundaGroupKey;
  final bool isActive;

  const RoleAssignment({
    required this.id,
    required this.roleName,
    required this.roleCode,
    required this.organizationId,
    this.organizationName,
    required this.departmentId,
    this.departmentName,
    this.camundaGroupKey,
    this.isActive = true,
  });

  RoleAssignment copyWith({bool? isActive}) {
    return RoleAssignment(
      id: id,
      roleName: roleName,
      roleCode: roleCode,
      organizationId: organizationId,
      organizationName: organizationName,
      departmentId: departmentId,
      departmentName: departmentName,
      camundaGroupKey: camundaGroupKey,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roleName,
        roleCode,
        organizationId,
        organizationName,
        departmentId,
        departmentName,
        camundaGroupKey,
        isActive,
      ];
}
