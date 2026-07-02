import 'package:equatable/equatable.dart';

/// A selectable location for the "create institution" form
/// (`GET /api/location`).
class LocationOption extends Equatable {
  final int id;
  final String name;

  /// The location's type, when the API includes `type_location`. Used to
  /// seed the type dropdown in the "add location" form (there is no dedicated
  /// list-types endpoint, so the choices are derived from existing locations).
  final int? typeId;
  final String? typeName;

  const LocationOption({
    required this.id,
    required this.name,
    this.typeId,
    this.typeName,
  });

  @override
  List<Object?> get props => [id, name, typeId, typeName];
}
