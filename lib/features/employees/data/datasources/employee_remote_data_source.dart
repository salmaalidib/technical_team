import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

class EmployeeRemoteDataSource {
  final ApiService api;

  EmployeeRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> createEmployee(
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.registerEmployee,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> getEmployees({
    required int page,
    required int limit,
    String? search,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.employees,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
  }

  Future<Either<Failure, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.employeeById(id),
      body: body,
    );
  }
}