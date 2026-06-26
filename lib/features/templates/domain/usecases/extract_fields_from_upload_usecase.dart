import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/extract_fields_result.dart';
import '../repositories/doc_template_repository.dart';

/// Create step 1: uploads the template PDF and reads its AcroForm fields plus
/// the stored file's `path`/`url`, which feed the final [CreateTemplateUseCase].
class ExtractFieldsFromUploadUseCase {
  final DocTemplateRepository repository;

  ExtractFieldsFromUploadUseCase(this.repository);

  Future<Either<Failure, ExtractFieldsResult>> call({
    required List<int> fileBytes,
    required String fileName,
  }) =>
      repository.extractFieldsFromUpload(
        fileBytes: fileBytes,
        fileName: fileName,
      );
}
