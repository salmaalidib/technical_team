import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/doc_template.dart';
import '../repositories/doc_template_repository.dart';

class GetTemplatesUseCase {
  final DocTemplateRepository repository;

  GetTemplatesUseCase(this.repository);

  Future<Either<Failure, Paginated<DocTemplate>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) =>
      repository.getTemplates(page: page, limit: limit, search: search);
}
