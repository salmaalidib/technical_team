import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/check_list_entity.dart';
import '../repositories/fields_repository.dart';

class GetCheckListsUseCase {
  final FieldsRepository repository;

  GetCheckListsUseCase(this.repository);

  Future<Either<Failure, Paginated<CheckListEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getCheckLists(page: page, limit: limit, search: search);
  }
}
