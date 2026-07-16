import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/text_dropdown_entity.dart';
import '../repositories/fields_repository.dart';

class GetTextDropdownsUseCase {
  final FieldsRepository repository;

  GetTextDropdownsUseCase(this.repository);

  Future<Either<Failure, Paginated<TextDropdownEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getTextDropdowns(page: page, limit: limit, search: search);
  }
}
