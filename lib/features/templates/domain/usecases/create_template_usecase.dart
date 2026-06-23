import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../repositories/doc_template_repository.dart';

/// Step 1 of authoring: create the template row from the uploaded file +
/// metadata. `config_json` is added afterwards via [UpdateTemplateUseCase].
class CreateTemplateUseCase {
  final DocTemplateRepository repository;

  CreateTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call({
    required String name,
    required int typeDocId,
    required List<int> fileBytes,
    required String fileName,
  }) {
    return repository.createTemplate(
      name: name,
      typeDocId: typeDocId,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }
}
