import 'package:equatable/equatable.dart';

/// A selectable location for the "create institution" form
/// (`GET /api/location`).
class LocationOption extends Equatable {
  final int id;
  final String name;

  const LocationOption({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
