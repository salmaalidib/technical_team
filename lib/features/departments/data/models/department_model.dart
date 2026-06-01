import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.name,
    required super.organizationId,
    super.parentId,
    super.isActive,
    super.organizationName,
    super.parentName,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'];
    final parent = json['parent'];

    return DepartmentModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      organizationId: (json['organization_id'] ?? 0) as int,
      parentId: json['parent_id'] as int?,
      isActive: (json['is_active'] ?? true) as bool,
      organizationName:
          organization is Map ? organization['name'] as String? : null,
      parentName: parent is Map ? parent['name'] as String? : null,
    );
  }
}
