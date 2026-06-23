import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the document-template endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
///
/// The backend models template authoring as **two steps**:
///   1. [createTemplate] — `POST` multipart with just the file + name +
///      type_doc_id; the row is created with `config_json = null`.
///   2. [updateTemplate] — `PUT` **JSON** with `config_json` only; it archives
///      the old version and creates a new one. The file/name/type are NOT
///      editable here.
/// Between the two, [extractFields] reads the PDF's AcroForm field names so the
/// technician can map each to a library field.
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

  /// `GET /api/document-templates/{id}/fields` — the saved template's extracted
  /// AcroForm fields.
  Future<Either<Failure, dynamic>> extractFields(int id) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.documentTemplateFields(id),
    );
  }

  /// Step 1 — `POST /api/document-templates` (multipart): template file (field
  /// name `file`) + `name` + `type_doc_id`. No `config_json` here; the backend
  /// ignores it and creates the row with `config_json = null`.
  Future<Either<Failure, dynamic>> createTemplate({
    required String name,
    required int typeDocId,
    required List<int> fileBytes,
    required String fileName,
  }) {
    final formData = dio.FormData.fromMap({
      'name': name,
      'type_doc_id': typeDocId,
      'file': dio.MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _ep.documentTemplates,
      formData: formData,
    );
  }

  /// Step 2 — `PUT /api/document-templates/{id}` (**JSON**): `config_json` only.
  /// The route has no upload middleware and validates `{ config_json }` with
  /// `unknown(false)`, so anything else would be rejected.
  Future<Either<Failure, dynamic>> updateConfig({
    required int id,
    required Map<String, dynamic> configJson,
  }) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _ep.documentTemplateById(id),
      body: {'config_json': configJson},
    );
  }
}
