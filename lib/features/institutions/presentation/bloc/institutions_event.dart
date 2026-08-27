import 'package:equatable/equatable.dart';

abstract class InstitutionsEvent extends Equatable {
  const InstitutionsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the institutions list together with the locations used by the
/// create form.
class LoadInstitutions extends InstitutionsEvent {
  const LoadInstitutions();
}

/// Submits a new institution. [parentId] and [locationId] are optional.
class CreateInstitutionRequested extends InstitutionsEvent {
  final String name;
  final int? parentId;
  final int? locationId;

  const CreateInstitutionRequested({
    required this.name,
    this.parentId,
    this.locationId,
  });

  @override
  List<Object?> get props => [name, parentId, locationId];
}

/// Drills into an institution's children, pushing it onto the breadcrumb trail.
class NavigateToChildren extends InstitutionsEvent {
  final int parentId;
  final String parentName;

  const NavigateToChildren({required this.parentId, required this.parentName});

  @override
  List<Object?> get props => [parentId, parentName];
}

/// Jumps to a crumb in the breadcrumb trail. `index == -1` is the root level.
class NavigateToCrumb extends InstitutionsEvent {
  final int index;

  const NavigateToCrumb(this.index);

  @override
  List<Object?> get props => [index];
}

/// Local (client-side) search within the current level.
class SearchChanged extends InstitutionsEvent {
  final String query;

  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Local (client-side) pagination of the current level.
class PageChanged extends InstitutionsEvent {
  final int page;

  const PageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// Changes how many rows the current level shows per page.
class PageSizeChanged extends InstitutionsEvent {
  final int size;

  const PageSizeChanged(this.size);

  @override
  List<Object?> get props => [size];
}

/// Submits a new location.
class CreateTypeLocationRequested extends InstitutionsEvent {
  final String name;

  const CreateTypeLocationRequested({required this.name});

  @override
  List<Object?> get props => [name];
}

class CreateLocationRequested extends InstitutionsEvent {
  final String name;
  final int typeLocationId;

  const CreateLocationRequested({
    required this.name,
    required this.typeLocationId,
  });

  @override
  List<Object?> get props => [name, typeLocationId];
}
