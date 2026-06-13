import 'package:equatable/equatable.dart';

/// A process type as returned by `GET /api/typeProcess` — a single row of the
/// `type_processes` table.
///
/// The backend exposes create (name + code) / list / toggle-status, so the
/// editable surface after creation is just [isActive].
class TypeProcess extends Equatable {
  final int id;
  final String name;

  /// Short uppercase identifier (`^[A-Z0-9_]{2,20}$`) — required on create.
  final String code;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeProcess({
    required this.id,
    required this.name,
    this.code = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  TypeProcess copyWith({bool? isActive}) {
    return TypeProcess(
      id: id,
      name: name,
      code: code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, code, isActive, createdAt, updatedAt];
}
