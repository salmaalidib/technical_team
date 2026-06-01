import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the department + organization endpoints. Error mapping
/// lives in [ApiService]; methods return the raw decoded body on the right.
class DepartmentRemoteDataSource {
  final ApiService api;

  DepartmentRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getDepartments() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.departments,
    );
  }

  Future<Either<Failure, dynamic>> getOrganizations() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.organizations,
    );
  }

  Future<Either<Failure, dynamic>> getOverview(int id) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.departmentOverview(id),
    );
  }

  Future<Either<Failure, dynamic>> createDepartment(
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.departments,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> toggleStatus(int id) {
    return api.makeRequest(
      method: ApiMethod.patch,
      endPoint: _endPoints.departmentToggleStatus(id),
    );
  }
}
