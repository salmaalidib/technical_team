import '../../domain/entities/created_employee.dart';

class CreatedEmployeeModel extends CreatedEmployee {
  const CreatedEmployeeModel({
    required super.userName,
    required super.firstName,
    required super.lastName,
    required super.fatherName,
    required super.motherName,
    required super.nationalId,
    required super.keyFingerprint,
    required super.organizationDepartmentRolesId,
    required super.message,
  });

  factory CreatedEmployeeModel.fromJson(Map<String, dynamic> json) {
    return CreatedEmployeeModel(
      userName: (json['userName'] ?? '') as String,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      fatherName: (json['father_name'] ?? '') as String,
      motherName: (json['mother_name'] ?? '') as String,
      nationalId: (json['national_id'] ?? '') as String,
      keyFingerprint: (json['key_fingerprint'] ?? '') as String,
      organizationDepartmentRolesId:
          (json['organization_department_roles_id'] ?? 0) as int,
      message: (json['message'] ?? '') as String,
    );
  }
}