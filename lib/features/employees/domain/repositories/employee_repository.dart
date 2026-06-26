import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/created_employee.dart';
import '../entities/employee.dart';
import '../entities/employees_page.dart';

abstract class EmployeeRepository {
  /// جلب الموظفين (مرقّم + بحث اختياري).
  Future<Either<Failure, EmployeesPage>> getEmployees({
    int page = 1,
    int limit = 20,
    String? search,
  });

  /// تعديل موظف. [data] حمولة جزئية بمفاتيح snake_case كما يتوقعها الـ backend.
  Future<Either<Failure, Employee>> updateEmployee({
    required int id,
    required Map<String, dynamic> data,
  });

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
    required String pin,
    required String confirmPin,
    required int organizationId,
    int? departmentId,
    int? roleId,
    required String publicKey,
  });
}
