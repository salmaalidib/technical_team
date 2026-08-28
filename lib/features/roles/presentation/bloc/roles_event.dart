import 'package:equatable/equatable.dart';

import '../../domain/entities/permission.dart';

abstract class RolesEvent extends Equatable {
  const RolesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the role links of [organizationId] — the backend filters by it and
/// rejects the request with a 400 when it is missing.
class LoadRoles extends RolesEvent {
  final int organizationId;

  const LoadRoles(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

/// Loads the leaf departments of an organization to populate the department
/// dropdown when the user picks an organization in the create form.
class LoadLeafDepartments extends RolesEvent {
  final int organizationId;

  const LoadLeafDepartments(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

/// Loads the permission options for the create-role form's checkbox list.
/// Fired once when the dialog opens. [audience] narrows the list to the
/// employee/admin routes (each includes the shared rows); default is all.
class LoadPermissions extends RolesEvent {
  final PermissionAudience audience;

  const LoadPermissions({this.audience = PermissionAudience.all});

  @override
  List<Object?> get props => [audience];
}

/// Loads every role defined in `roles` — the create form's dropdown of
/// existing roles, so a role already in the system is linked rather than
/// redefined under a duplicate code.
class LoadRoleCatalog extends RolesEvent {
  const LoadRoleCatalog();
}

class CreateRoleRequested extends RolesEvent {
  /// Id of an existing role to link. Mutually exclusive with [name] / [code];
  /// exactly one of the two modes must be set.
  final int? roleId;

  /// Name and code of a role to define. Both null when [roleId] is used.
  final String? name;
  final String? code;

  final int organizationId;
  final int departmentId;

  /// Link id of the parent role, or null for a root role. Optional in the
  /// form and nullable in the backend.
  final int? parentId;

  /// Optional: the role is created first, then these are attached in a second
  /// request. Empty means "create the role with no permissions".
  final List<int> permissionIds;

  const CreateRoleRequested({
    this.roleId,
    this.name,
    this.code,
    required this.organizationId,
    required this.departmentId,
    this.parentId,
    this.permissionIds = const [],
  });

  @override
  List<Object?> get props => [
        roleId,
        name,
        code,
        organizationId,
        departmentId,
        parentId,
        permissionIds,
      ];
}

class ToggleRoleStatus extends RolesEvent {
  final int id;

  const ToggleRoleStatus(this.id);

  @override
  List<Object?> get props => [id];
}

/// Opens the edit-permissions dialog for a role: loads the full permission
/// list and the role's currently-granted ones so the boxes start pre-checked.
class OpenEditPermissions extends RolesEvent {
  final int organizationId;
  final int departmentId;
  final int roleId;

  const OpenEditPermissions({
    required this.organizationId,
    required this.departmentId,
    required this.roleId,
  });

  @override
  List<Object?> get props => [organizationId, departmentId, roleId];
}

/// Replaces the role's permissions wholesale via PUT — an empty list clears
/// every permission.
class SaveEditedPermissions extends RolesEvent {
  final int organizationId;
  final int departmentId;
  final int roleId;
  final List<int> permissionIds;

  const SaveEditedPermissions({
    required this.organizationId,
    required this.departmentId,
    required this.roleId,
    required this.permissionIds,
  });

  @override
  List<Object?> get props =>
      [organizationId, departmentId, roleId, permissionIds];
}

/// Loads the roles linked to a single (leaf) department — used when registering
/// an employee after the department is chosen.
class LoadRolesByDepartment extends RolesEvent {
  final int departmentId;

  const LoadRolesByDepartment(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}
