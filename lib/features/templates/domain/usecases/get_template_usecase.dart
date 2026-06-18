import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../repositories/doc_template_repository.dart';

class GetTemplateUseCase {
  final DocTemplateRepository repository;

  GetTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call(int id) =>
      repository.getTemplate(id);
}
