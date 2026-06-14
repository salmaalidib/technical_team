import 'package:equatable/equatable.dart';

abstract class TypeDocsEvent extends Equatable {
  const TypeDocsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the document-types list.
class LoadTypeDocs extends TypeDocsEvent {
  const LoadTypeDocs();
}

class CreateTypeDocRequested extends TypeDocsEvent {
  final String name;

  const CreateTypeDocRequested({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Renames a document type via `PUT /api/typeDoc/{id}` with `{ name }`.
class RenameTypeDocRequested extends TypeDocsEvent {
  final int id;
  final String name;

  const RenameTypeDocRequested({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Soft-deletes a document type via `PUT /api/typeDoc/{id}` with
/// `{ is_active: false }` (the backend has no hard-delete endpoint).
class DeactivateTypeDocRequested extends TypeDocsEvent {
  final int id;

  const DeactivateTypeDocRequested({required this.id});

  @override
  List<Object?> get props => [id];
}
