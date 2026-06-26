import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the document-template endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
///
/// The backend models **creation** as: upload-then-create.
///   1. [extractFieldsFromUpload] — `POST /extract-fields` multipart (`file`
///      only). The backend stores the PDF and returns its AcroForm `fields`
///      plus the `path`/`url` it assigned. No row is created yet.
///   2. [createTemplate] — `POST /` **JSON** with `name`, `type_doc_id`, the
///      `path`/`url` from step 1 (verbatim), and the built `config_json`. One
///      call creates the fully-configured row.
///
/// **Editing** stays separate:
///   * [extractFields] — `GET /{id}/fields` reads a saved template's fields.
///   * [updateConfig] — `PUT /{id}` **JSON** `config_json` only; archives the
///     old version and creates a new one. File/name/type are not editable here.
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

  /// `GET /api/document-templates/{id}/fields` — the saved template's extracted
  /// AcroForm fields (used by the **edit** flow).
  Future<Either<Failure, dynamic>> extractFields(int id) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _ep.documentTemplateFields(id),
    );
  }

  /// Create step 1 — `POST /api/document-templates/extract-fields` (multipart):
  /// the template file only (field name `file`). Returns `data.fields[]` plus
  /// the `path`/`url` the backend assigned to the stored file — no row is
  /// created. The returned `path`/`url` are fed back into [createTemplate].
  Future<Either<Failure, dynamic>> extractFieldsFromUpload({
    required List<int> fileBytes,
    required String fileName,
  }) {
    final formData = dio.FormData.fromMap({
      'file': dio.MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _ep.documentTemplatesExtractFields,
      formData: formData,
    );
  }

  /// Create step 2 — `POST /api/document-templates` (**JSON**): the full record
  /// in one call — `name`, `type_doc_id`, the `path`/`url` returned by
  /// [extractFieldsFromUpload] (verbatim — `url` must match `path`), and the
  /// built `config_json`.
  Future<Either<Failure, dynamic>> createTemplate({
    required String name,
    required int typeDocId,
    required String path,
    required String url,
    required Map<String, dynamic> configJson,
  }) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _ep.documentTemplates,
      body: {
        'name': name,
        'type_doc_id': typeDocId,
        'path': path,
        'url': url,
        'config_json': configJson,
      },
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
