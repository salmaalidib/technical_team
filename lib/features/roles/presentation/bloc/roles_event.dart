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

class CreateRoleRequested extends RolesEvent {
  final String name;
  final String code;
  final int organizationId;
  final int departmentId;

  const CreateRoleRequested({
    required this.name,
    required this.code,
    required this.organizationId,
    required this.departmentId,
  });

  @override
  List<Object?> get props => [name, code, organizationId, departmentId];
}

class ToggleRoleStatus extends RolesEvent {
  final int id;

  const ToggleRoleStatus(this.id);

  @override
  List<Object?> get props => [id];
}
