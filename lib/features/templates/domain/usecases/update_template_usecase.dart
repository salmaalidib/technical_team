import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/form_config.dart';
import '../repositories/doc_template_repository.dart';

class UpdateTemplateUseCase {
  final DocTemplateRepository repository;

  UpdateTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call({
    required int id,
    String? name,
    int? typeDocId,
    FormConfig? config,
    List<int>? fileBytes,
    String? fileName,
  }) {
    return repository.updateTemplate(
      id: id,
      name: name,
      typeDocId: typeDocId,
      config: config,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }
}
