import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the document-template endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class DocTemplateRemoteDataSource {
  final ApiService api;

  DocTemplateRemoteDataSource(this.api);

  static const _ep = EndPoints();

  Future<Either<Failure, dynamic>> getTemplates() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.documentTemplates,
    );
  }

  Future<Either<Failure, dynamic>> getTemplate(int id) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.documentTemplateById(id),
    );
  }

  /// `POST /api/document-templates` — multipart: template file (field name
  /// `file`) + `name`, `type_doc_id`, `config_json` (JSON string).
  Future<Either<Failure, dynamic>> createTemplate({
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
      endPoint: _ep.documentTemplates,
      formData: formData,
    );
  }

  /// `PUT /api/document-templates/{id}` — multipart; the file is optional, so
  /// it is only attached when [fileBytes]/[fileName] are provided.
  Future<Either<Failure, dynamic>> updateTemplate({
    required int id,
    required Map<String, dynamic> fields,
    List<int>? fileBytes,
    String? fileName,
  }) {
    final formData = dio.FormData.fromMap({
      ...fields,
      if (fileBytes != null && fileName != null)
        'file': dio.MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _ep.documentTemplateById(id),
      formData: formData,
    );
  }
}
