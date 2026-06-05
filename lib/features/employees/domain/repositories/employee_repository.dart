import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/created_employee.dart';

abstract class EmployeeRepository {
  Future<Either<Failure, CreatedEmployee>> createEmployee({
    required String firstName,
    required String lastName,
    required String fatherName,
    required String motherName,
    required String nationalId,
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
    required int organizationId,
    int? departmentId,
    int? roleId,
    required String publicKey,
  });
}