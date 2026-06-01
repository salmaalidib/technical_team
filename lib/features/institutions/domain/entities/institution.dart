import 'package:equatable/equatable.dart';

/// A single organization/institution as returned by `GET /api/organization`.
class Institution extends Equatable {
  final int id;
  final String name;
  final int? parentId;
  final int? locationId;

  /// Names resolved from the embedded `parent` / `location` relations, when
  /// the backend includes them (list & detail endpoints do).
  final String? parentName;
  final String? locationName;

  const Institution({
    required this.id,
    required this.name,
    this.parentId,
    this.locationId,
    this.parentName,
    this.locationName,
  });

  @override
  List<Object?> get props =>
      [id, name, parentId, locationId, parentName, locationName];
}
