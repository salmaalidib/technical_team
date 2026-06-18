import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the process-builder endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class ProcessBuilderRemoteDataSource {
  final ApiService api;

  ProcessBuilderRemoteDataSource(this.api);

  static const _ep = EndPoints();

  /// `POST /api/process_definitions/create` — multipart: BPMN file (field
  /// name `file`) + the metadata fields.
  Future<Either<Failure, dynamic>> createProcessDefinition({
    required Map<String, dynamic> fields,
    required List<int> fileBytes,
    required String fileName,
  }) {
    final formData = dio.FormData.fromMap({
      ...fields,
      'file': dio.MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _ep.processDefinitionCreate,
      formData: formData,
    );
  }

  /// `POST /api/stage_config/create`.
  Future<Either<Failure, dynamic>> createStageConfig(
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _ep.stageConfigCreate,
      body: body,
    );
  }

  /// `GET /api/process_definitions/admin/review-queue` — unapproved/inactive.
  Future<Either<Failure, dynamic>> getReviewQueue({
    required int page,
    required int limit,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.processDefinitionReviewQueue,
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// `GET /api/process_definitions/admin/type/{id}` — all processes of a type
  /// (`typeId` `0` = every type).
  Future<Either<Failure, dynamic>> getProcessesByType({
    required int typeId,
    required int page,
    required int limit,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.processDefinitionsByType(typeId),
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// `GET /api/process_definitions/{id}/details` — full details + validation.
  Future<Either<Failure, dynamic>> getProcessDetails(int id) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.processDefinitionDetails(id),
    );
  }
}
