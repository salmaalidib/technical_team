import '../../domain/entities/role_by_department.dart';

class RoleByDepartmentModel extends RoleByDepartment {
  const RoleByDepartmentModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory RoleByDepartmentModel.fromJson(Map<String, dynamic> json) {
    return RoleByDepartmentModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
    );
  }
}
