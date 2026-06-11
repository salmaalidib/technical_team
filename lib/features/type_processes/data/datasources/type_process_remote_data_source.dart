import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the process-type endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class TypeProcessRemoteDataSource {
  final ApiService api;

  TypeProcessRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getTypeProcesses() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.typeProcesses,
    );
  }

  Future<Either<Failure, dynamic>> createTypeProcess(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.typeProcesses,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> updateTypeProcess(
    int id,
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.typeProcessById(id),
      body: body,
    );
  }
}
