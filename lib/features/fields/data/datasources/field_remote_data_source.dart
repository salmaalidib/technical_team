import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the dynamic-field endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class FieldRemoteDataSource {
  final ApiService api;

  FieldRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getFields() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.fields,
    );
  }

  Future<Either<Failure, dynamic>> createField(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.fields,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> updateField(
    int id,
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.fieldById(id),
      body: body,
    );
  }
}
