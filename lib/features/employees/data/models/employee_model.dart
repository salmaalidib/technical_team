import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.userName,
    required super.email,
    required super.phoneNumber,
    required super.firstName,
    required super.lastName,
    required super.fatherName,
    required super.motherName,
    required super.nationalId,
    required super.isActive,
    super.organization,
    super.department,
    super.role,
    super.organizationDepartmentRolesId,
  });

  static NamedRef? _ref(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id == null) return null;
    return NamedRef(
      id: id as int,
      name: (json['name'] ?? '') as String,
      code: json['code'] as String?,
    );
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: (json['id'] ?? 0) as int,
      userName: (json['userName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phone_number'] ?? '') as String,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      fatherName: (json['father_name'] ?? '') as String,
      motherName: (json['mother_name'] ?? '') as String,
      nationalId: (json['national_id'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      organization: _ref(json['organization']),
      department: _ref(json['department']),
      role: _ref(json['role']),
      organizationDepartmentRolesId:
          json['organization_department_roles_id'] as int?,
    );
  }
}
