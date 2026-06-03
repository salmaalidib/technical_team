import 'package:equatable/equatable.dart';

/// A reusable dynamic field as returned by `GET /api/fields`.
///
/// [listValues] is only populated for the `choice` / `multiChoice` types
/// (the backend stores it in `list_json`).
class DynamicField extends Equatable {
  final int id;
  final String fieldName;
  final String fieldType;
  final List<String>? listValues;

  const DynamicField({
    required this.id,
    required this.fieldName,
    required this.fieldType,
    this.listValues,
  });

  @override
  List<Object?> get props => [id, fieldName, fieldType, listValues];
}
