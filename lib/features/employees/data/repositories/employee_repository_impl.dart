import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/created_employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_data_source.dart';
import '../models/created_employee_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remote;

  EmployeeRepositoryImpl(this.remote);

  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
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
  }) async {
    final result = await remote.createEmployee({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'father_name': fatherName.trim(),
      'mother_name': motherName.trim(),
      'national_id': nationalId.trim(),
      'userName': userName.trim(),
      'email': email.trim(),
      'phone_number': phoneNumber.trim(),
      'password': password.trim(),
      'organization_id': organizationId,
      if (departmentId != null) 'department_id': departmentId,
      if (roleId != null) 'role_id': roleId,
      'public_key': publicKey.trim(),
    });

    return result.fold<Either<Failure, CreatedEmployee>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            CreatedEmployeeModel.fromJson(
              _payload(body) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة إنشاء الموظف.'));
        }
      },
    );
  }
}
