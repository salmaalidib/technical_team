import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/created_employee.dart';
import '../repositories/employee_repository.dart';

class CreateEmployeeUseCase {
  final EmployeeRepository repository;

  CreateEmployeeUseCase(this.repository);

  Future<Either<Failure, CreatedEmployee>> call({
    required String firstName,
    required String lastName,
    required String fatherName,
    required String motherName,
    required String nationalId,
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
    required String pin,
    required String confirmPin,
    required int organizationId,
    int? departmentId,
    int? roleId,
    required String publicKey,
  }) {
    return repository.createEmployee(
      firstName: firstName,
      lastName: lastName,
      fatherName: fatherName,
      motherName: motherName,
      nationalId: nationalId,
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      organizationId: organizationId,
      departmentId: departmentId,
      roleId: roleId,
      publicKey: publicKey,
      pin: pin,
      confirmPin: confirmPin,
    );
  }
}
