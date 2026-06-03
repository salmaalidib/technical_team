import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the file-definition endpoints.
class FileRemoteDataSource {
  final ApiService api;

  FileRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getFiles() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.files,
    );
  }

  Future<Either<Failure, dynamic>> createFile(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.files,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> updateFile(
    int id,
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.fileById(id),
      body: body,
    );
  }
}
