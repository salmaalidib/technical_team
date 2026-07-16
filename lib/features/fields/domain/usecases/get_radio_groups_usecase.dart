import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/radio_group_entity.dart';
import '../repositories/fields_repository.dart';

class GetRadioGroupsUseCase {
  final FieldsRepository repository;

  GetRadioGroupsUseCase(this.repository);

  Future<Either<Failure, Paginated<RadioGroupEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getRadioGroups(page: page, limit: limit, search: search);
  }
}
