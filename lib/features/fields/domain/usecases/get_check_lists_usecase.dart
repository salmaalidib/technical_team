import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/check_list_entity.dart';
import '../repositories/fields_repository.dart';

class GetCheckListsUseCase {
  final FieldsRepository repository;

  GetCheckListsUseCase(this.repository);

  Future<Either<Failure, List<CheckListEntity>>> call() {
    return repository.getCheckLists();
  }
}
