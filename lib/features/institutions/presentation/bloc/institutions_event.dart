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

/// Submits a new institution. [locationId] is optional.
class CreateInstitutionRequested extends InstitutionsEvent {
  final String name;
  final int? locationId;

  const CreateInstitutionRequested({
    required this.name,
    this.locationId,
  });

  @override
  List<Object?> get props => [name, locationId];
}

/// Submits a new location.
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
