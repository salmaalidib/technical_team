import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../repositories/doc_template_repository.dart';

class GetTemplatesUseCase {
  final DocTemplateRepository repository;

  GetTemplatesUseCase(this.repository);

  Future<Either<Failure, List<DocTemplate>>> call() => repository.getTemplates();
}
