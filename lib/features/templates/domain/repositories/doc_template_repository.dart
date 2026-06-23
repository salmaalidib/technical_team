import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/extracted_field.dart';
import '../entities/form_config.dart';

/// Document-template management for the technical team. Authoring is two-step,
/// mirroring the backend:
/// * [getTemplates]   → `GET  /api/document-templates`
/// * [getTemplate]    → `GET  /api/document-templates/{id}`
/// * [createTemplate] → `POST /api/document-templates` (multipart: file + meta;
///   created with `config_json = null`)
/// * [extractFields]  → `GET  /api/document-templates/{id}/fields` (PDF fields)
/// * [updateConfig]   → `PUT  /api/document-templates/{id}` (JSON `config_json`;
///   the backend archives the old version and creates a new one)
abstract class DocTemplateRepository {
  Future<Either<Failure, List<DocTemplate>>> getTemplates();

  Future<Either<Failure, DocTemplate>> getTemplate(int id);

  /// Step 1: creates the row from the uploaded file + metadata only. Returns
  /// the created template (its `config` is still null).
  Future<Either<Failure, DocTemplate>> createTemplate({
    required String name,
    required int typeDocId,
    required List<int> fileBytes,
    required String fileName,
  });

  /// The saved template's extracted AcroForm field names.
  Future<Either<Failure, List<ExtractedField>>> extractFields(int id);

  /// Step 2: sets `config_json` on the template. The backend returns the new
  /// (latest) version.
  Future<Either<Failure, DocTemplate>> updateConfig({
    required int id,
    required FormConfig config,
  });
}
