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

/// Submits a new institution. [parentId] / [locationId] are optional.
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
