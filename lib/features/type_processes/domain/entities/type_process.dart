import 'package:equatable/equatable.dart';

/// A process type as returned by `GET /api/typeProcess` — a single row of the
/// `type_processes` table.
///
/// The backend only exposes create (name) / list / toggle-status, so the
/// editable surface is just [isActive].
class TypeProcess extends Equatable {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeProcess({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  TypeProcess copyWith({bool? isActive}) {
    return TypeProcess(
      id: id,
      name: name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, isActive, createdAt, updatedAt];
}
