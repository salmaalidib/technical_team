import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/form_config.dart';

/// Document-template management for the technical team:
/// * [getTemplates]   → `GET  /api/document-templates`
/// * [getTemplate]    → `GET  /api/document-templates/{id}`
/// * [createTemplate] → `POST /api/document-templates` (multipart: file + meta)
/// * [updateTemplate] → `PUT  /api/document-templates/{id}` (multipart; the
///   backend archives the old version and creates a new one)
abstract class DocTemplateRepository {
  Future<Either<Failure, List<DocTemplate>>> getTemplates();

  Future<Either<Failure, DocTemplate>> getTemplate(int id);

  Future<Either<Failure, DocTemplate>> createTemplate({
    required String name,
    required int typeDocId,
    required FormConfig config,
    required List<int> fileBytes,
    required String fileName,
  });

  /// On update the file is optional — omit [fileBytes]/[fileName] to keep the
  /// existing file.
  Future<Either<Failure, DocTemplate>> updateTemplate({
    required int id,
    String? name,
    int? typeDocId,
    FormConfig? config,
    List<int>? fileBytes,
    String? fileName,
  });
}
