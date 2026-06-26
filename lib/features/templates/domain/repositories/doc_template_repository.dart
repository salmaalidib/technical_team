import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/extract_fields_result.dart';
import '../entities/extracted_field.dart';
import '../entities/form_config.dart';

/// Document-template management for the technical team.
///
/// **Creation** is upload-then-create:
/// * [extractFieldsFromUpload] → `POST /api/document-templates/extract-fields`
///   (multipart: file only). Returns the PDF fields + the stored file's
///   `path`/`url`; no row is created.
/// * [createTemplate] → `POST /api/document-templates` (JSON: name + type +
///   path + url + config_json). One call creates the fully-configured row.
///
/// **Editing** an existing template:
/// * [extractFields]  → `GET  /api/document-templates/{id}/fields` (PDF fields)
/// * [updateConfig]   → `PUT  /api/document-templates/{id}` (JSON `config_json`;
///   the backend archives the old version and creates a new one)
///
/// Plus the read:
/// * [getTemplates]   → `GET  /api/document-templates`
abstract class DocTemplateRepository {
  Future<Either<Failure, List<DocTemplate>>> getTemplates();

  /// Create step 1: uploads the PDF and returns its extracted fields together
  /// with the `path`/`url` the backend assigned (fed into [createTemplate]).
  Future<Either<Failure, ExtractFieldsResult>> extractFieldsFromUpload({
    required List<int> fileBytes,
    required String fileName,
  });

  /// Create step 2: creates the fully-configured row in one JSON call. [path]
  /// and [url] must be the values returned by [extractFieldsFromUpload].
  Future<Either<Failure, DocTemplate>> createTemplate({
    required String name,
    required int typeDocId,
    required String path,
    required String url,
    required FormConfig config,
  });

  /// An existing template's extracted AcroForm field names (edit flow).
  Future<Either<Failure, List<ExtractedField>>> extractFields(int id);

  /// Sets `config_json` on an existing template. The backend returns the new
  /// (latest) version.
  Future<Either<Failure, DocTemplate>> updateConfig({
    required int id,
    required FormConfig config,
  });
}
