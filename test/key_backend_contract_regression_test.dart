import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/core/services/api_service.dart';
import 'package:technical_team/core/errors/failures.dart';
import 'package:technical_team/features/employees/data/datasources/employee_remote_data_source.dart';
import 'package:technical_team/features/employees/data/repositories/employee_repository_impl.dart';

class _CapturingEmployeeRemoteDataSource extends EmployeeRemoteDataSource {
  Map<String, dynamic>? createBody;
  Map<String, dynamic>? updateBody;
  int? updatedId;

  _CapturingEmployeeRemoteDataSource() : super(ApiService(Dio()));

  @override
  Future<Either<Failure, dynamic>> createEmployee(
    Map<String, dynamic> body,
  ) async {
    createBody = Map.of(body);
    return const Right({
      'data': {
        'userName': 'employee',
        'first_name': 'First',
        'last_name': 'Last',
        'father_name': 'Father',
        'mother_name': 'Mother',
        'national_id': '123',
        'key_fingerprint': 'fingerprint',
        'organization_department_roles_id': 7,
        'message': 'created',
      },
    });
  }

  @override
  Future<Either<Failure, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> body,
  ) async {
    updatedId = id;
    updateBody = Map.of(body);
    return Right({
      'data': {
        'id': id,
        'userName': 'employee',
        'email': 'employee@example.com',
        'phone_number': '0999999999',
        'first_name': 'First',
        'last_name': 'Last',
        'father_name': 'Father',
        'mother_name': 'Mother',
        'national_id': '123',
        'is_active': true,
      },
    });
  }
}

void main() {
  const pem = '-----BEGIN PUBLIC KEY-----\nABC123\n-----END PUBLIC KEY-----';

  test('employee creation request keeps the existing backend contract',
      () async {
    final remote = _CapturingEmployeeRemoteDataSource();
    final repository = EmployeeRepositoryImpl(remote);

    final result = await repository.createEmployee(
      firstName: 'First',
      lastName: 'Last',
      fatherName: 'Father',
      motherName: 'Mother',
      nationalId: '123',
      userName: 'employee',
      email: 'employee@example.com',
      phoneNumber: '0999999999',
      password: 'Password1',
      pin: '123456',
      confirmPin: '123456',
      organizationId: 1,
      departmentId: 2,
      roleId: 3,
      publicKey: pem,
    );

    expect(result.isRight(), isTrue);
    expect(remote.createBody?['public_key'], pem);
    expect(remote.createBody, isNot(contains('usb_fingerprint_hash')));
    expect(remote.createBody, isNot(contains('client_key_id')));
    expect(remote.createBody, isNot(contains('binding_token')));
    expect(remote.createBody, isNot(contains('private_key')));
  });

  test('employee public key update sends no local binding fields', () async {
    final remote = _CapturingEmployeeRemoteDataSource();
    final repository = EmployeeRepositoryImpl(remote);

    final result = await repository.updateEmployee(
      id: 9,
      data: const {
        'pin': '123456',
        'confirm_pin': '123456',
        'public_key': pem,
      },
    );

    expect(result.isRight(), isTrue);
    expect(remote.updatedId, 9);
    expect(remote.updateBody?['public_key'], pem);
    expect(remote.updateBody, isNot(contains('usb_fingerprint_hash')));
    expect(remote.updateBody, isNot(contains('client_key_id')));
    expect(remote.updateBody, isNot(contains('binding_token')));
    expect(remote.updateBody, isNot(contains('private_key')));
  });
}
