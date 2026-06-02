import '../../domain/entities/leaf_department.dart';

class LeafDepartmentModel extends LeafDepartment {
  const LeafDepartmentModel({required super.id, required super.name});

  factory LeafDepartmentModel.fromJson(Map<String, dynamic> json) {
    return LeafDepartmentModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
    );
  }
}
