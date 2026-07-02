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
/// sections / transactions), surfaced in the details dialog.
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

/// Drills into a department's children, pushing it onto the breadcrumb trail.
class NavigateToChildren extends DepartmentsEvent {
  final int parentId;
  final String parentName;

  const NavigateToChildren({required this.parentId, required this.parentName});

  @override
  List<Object?> get props => [parentId, parentName];
}

/// Jumps to a crumb in the breadcrumb trail. `index == -1` is the root level.
class NavigateToCrumb extends DepartmentsEvent {
  final int index;

  const NavigateToCrumb(this.index);

  @override
  List<Object?> get props => [index];
}

/// Local (client-side) search within the current level.
class SearchChanged extends DepartmentsEvent {
  final String query;

  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Local (client-side) pagination of the current level.
class PageChanged extends DepartmentsEvent {
  final int page;

  const PageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// Changes how many rows the current level shows per page.
class PageSizeChanged extends DepartmentsEvent {
  final int size;

  const PageSizeChanged(this.size);

  @override
  List<Object?> get props => [size];
}
