import 'package:equatable/equatable.dart';

abstract class RolesEvent extends Equatable {
  const RolesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the roles list together with the organizations used by the create
/// form.
class LoadRoles extends RolesEvent {
  const LoadRoles();
}

/// Loads the leaf departments of an organization to populate the department
/// dropdown when the user picks an organization in the create form.
class LoadLeafDepartments extends RolesEvent {
  final int organizationId;

  const LoadLeafDepartments(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

/// Loads every permission in the system to populate the create-role form's
/// checkbox list. Fired once when the dialog opens.
class LoadPermissions extends RolesEvent {
  const LoadPermissions();
}

class CreateRoleRequested extends RolesEvent {
  final String name;
  final String code;
  final int organizationId;
  final int departmentId;

  /// Optional: the role is created first, then these are attached in a second
  /// request. Empty means "create the role with no permissions".
  final List<int> permissionIds;

  const CreateRoleRequested({
    required this.name,
    required this.code,
    required this.organizationId,
    required this.departmentId,
    this.permissionIds = const [],
  });

  @override
  List<Object?> get props =>
      [name, code, organizationId, departmentId, permissionIds];
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
