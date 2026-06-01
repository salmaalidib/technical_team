import 'package:equatable/equatable.dart';

abstract class DepartmentsEvent extends Equatable {
  const DepartmentsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the departments list together with the organizations used by the
/// create form.
class LoadDepartments extends DepartmentsEvent {
  const LoadDepartments();
}

/// Lazily loads a single department's overview (manager / employees /
/// sections / transactions) when its card is expanded.
class LoadDepartmentOverview extends DepartmentsEvent {
  final int id;

  const LoadDepartmentOverview(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateDepartmentRequested extends DepartmentsEvent {
  final String name;
  final int organizationId;
  final int? parentId;

  const CreateDepartmentRequested({
    required this.name,
    required this.organizationId,
    this.parentId,
  });

  @override
  List<Object?> get props => [name, organizationId, parentId];
}

class ToggleDepartmentStatus extends DepartmentsEvent {
  final int id;

  const ToggleDepartmentStatus(this.id);

  @override
  List<Object?> get props => [id];
}
