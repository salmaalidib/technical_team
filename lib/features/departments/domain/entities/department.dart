import 'package:equatable/equatable.dart';

/// A department as returned by `GET /api/department`.
class Department extends Equatable {
  final int id;
  final String name;
  final int organizationId;
  final int? parentId;
  final bool isActive;

  /// Resolved from the embedded `organization` / `parent` relations.
  final String? organizationName;
  final String? parentName;

  const Department({
    required this.id,
    required this.name,
    required this.organizationId,
    this.parentId,
    this.isActive = true,
    this.organizationName,
    this.parentName,
  });

  Department copyWith({bool? isActive}) {
    return Department(
      id: id,
      name: name,
      organizationId: organizationId,
      parentId: parentId,
      isActive: isActive ?? this.isActive,
      organizationName: organizationName,
      parentName: parentName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        organizationId,
        parentId,
        isActive,
        organizationName,
        parentName,
      ];
}
