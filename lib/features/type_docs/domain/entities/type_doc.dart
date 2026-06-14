import 'package:equatable/equatable.dart';

/// A document type as returned by `GET /api/typeDoc` — a single row of the
/// `type_docs` table.
///
/// The backend exposes create (name) / list / update (name + is_active). There
/// is no hard delete; "deleting" means deactivating via `is_active = false`,
/// which also removes the type from the file-picker dropdown (the backend
/// rejects inactive types when creating a file picker).
class TypeDoc extends Equatable {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeDoc({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  TypeDoc copyWith({String? name, bool? isActive}) {
    return TypeDoc(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, isActive, createdAt, updatedAt];
}
