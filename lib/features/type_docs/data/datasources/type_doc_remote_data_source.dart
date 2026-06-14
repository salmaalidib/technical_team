import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the document-type endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class TypeDocRemoteDataSource {
  final ApiService api;

  TypeDocRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getTypeDocs() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.typeDocs,
    );
  }

  Future<Either<Failure, dynamic>> createTypeDoc(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.typeDocs,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> updateTypeDoc(
    int id,
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.typeDocById(id),
      body: body,
    );
  }
}
