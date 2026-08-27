import 'package:equatable/equatable.dart';

/// A location type (محافظة، منطقة، ناحية...) from `GET /api/type-location`.
///
/// Fills the "type" dropdown of the add-location form. Previously the choices
/// were derived from the types of already-loaded locations, so a type with no
/// locations yet could never be picked — and there was no way to add one.
class TypeLocationOption extends Equatable {
  final int id;
  final String name;

  const TypeLocationOption({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
