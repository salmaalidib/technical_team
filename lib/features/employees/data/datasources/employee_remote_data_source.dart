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
}