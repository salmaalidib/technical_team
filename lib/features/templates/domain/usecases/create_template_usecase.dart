import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/form_config.dart';
import '../repositories/doc_template_repository.dart';

class CreateTemplateUseCase {
  final DocTemplateRepository repository;

  CreateTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call({
    required String name,
    required int typeDocId,
    required FormConfig config,
    required List<int> fileBytes,
    required String fileName,
  }) {
    return repository.createTemplate(
      name: name,
      typeDocId: typeDocId,
      config: config,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }
}
