import 'package:equatable/equatable.dart';

abstract class EmployeesEvent extends Equatable {
  const EmployeesEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeeFormData extends EmployeesEvent {
  const LoadEmployeeFormData();
}

class LoadEmployeeDepartments extends EmployeesEvent {
  final int organizationId;

  const LoadEmployeeDepartments(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class LoadEmployeeRoles extends EmployeesEvent {
  final int departmentId;

  const LoadEmployeeRoles(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}

class CreateEmployeeRequested extends EmployeesEvent {
  final String firstName;
  final String lastName;
  final String fatherName;
  final String motherName;
  final String nationalId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String password;
  final int organizationId;
  final int? departmentId;
  final int? roleId;
  final String publicKey;

  const CreateEmployeeRequested({
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.motherName,
    required this.nationalId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.organizationId,
    this.departmentId,
    this.roleId,
    required this.publicKey,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        fatherName,
        motherName,
        nationalId,
        userName,
        email,
        phoneNumber,
        password,
        organizationId,
        departmentId,
        roleId,
        publicKey,
      ];
}
