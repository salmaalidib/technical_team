import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the role-assignment endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class RoleRemoteDataSource {
  final ApiService api;

  RoleRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getRoles() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.roles,
    );
  }

  Future<Either<Failure, dynamic>> createRole(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.roles,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> toggleStatus(int id) {
    return api.makeRequest(
      method: ApiMethod.patch,
      endPoint: _endPoints.roleToggleStatus(id),
    );
  }
}
