import 'package:equatable/equatable.dart';

class CreatedEmployee extends Equatable {
  final String userName;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String motherName;
  final String nationalId;
  final String keyFingerprint;
  final int organizationDepartmentRolesId;
  final String message;

  const CreatedEmployee({
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.motherName,
    required this.nationalId,
    required this.keyFingerprint,
    required this.organizationDepartmentRolesId,
    required this.message,
  });

  @override
  List<Object?> get props => [
        userName,
        firstName,
        lastName,
        fatherName,
        motherName,
        nationalId,
        keyFingerprint,
        organizationDepartmentRolesId,
        message,
      ];
}