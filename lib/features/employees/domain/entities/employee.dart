import 'package:equatable/equatable.dart';

/// مرجع مختصر (id + اسم) لمؤسسة/قسم/دور كما يعيدها الـ backend.
class NamedRef extends Equatable {
  final int id;
  final String name;
  final String? code;

  const NamedRef({required this.id, required this.name, this.code});

  @override
  List<Object?> get props => [id, name, code];
}

/// موظف كامل كما تعيده `GET /api/employees` و `GET /api/employees/:id`.
class Employee extends Equatable {
  final int id;
  final String userName;
  final String email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String motherName;
  final String nationalId;
  final bool isActive;

  final NamedRef? organization;
  final NamedRef? department;
  final NamedRef? role;
  final int? organizationDepartmentRolesId;

  const Employee({
    required this.id,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.motherName,
    required this.nationalId,
    required this.isActive,
    this.organization,
    this.department,
    this.role,
    this.organizationDepartmentRolesId,
  });

  /// الاسم الكامل (الأول + الأب + الأخير) لعرضه في الجدول.
  String get fullName =>
      [firstName, fatherName, lastName].where((p) => p.trim().isNotEmpty).join(' ');

  Employee copyWith({
    int? id,
    String? userName,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? motherName,
    String? nationalId,
    bool? isActive,
    NamedRef? organization,
    NamedRef? department,
    NamedRef? role,
    int? organizationDepartmentRolesId,
  }) {
    return Employee(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      nationalId: nationalId ?? this.nationalId,
      isActive: isActive ?? this.isActive,
      organization: organization ?? this.organization,
      department: department ?? this.department,
      role: role ?? this.role,
      organizationDepartmentRolesId:
          organizationDepartmentRolesId ?? this.organizationDepartmentRolesId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userName,
        email,
        phoneNumber,
        firstName,
        lastName,
        fatherName,
        motherName,
        nationalId,
        isActive,
        organization,
        department,
        role,
        organizationDepartmentRolesId,
      ];
}
