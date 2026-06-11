import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/check_list_entity.dart';
import '../repositories/fields_repository.dart';

class CreateCheckListUseCase {
  final FieldsRepository repository;

  CreateCheckListUseCase(this.repository);

  Future<Either<Failure, CheckListEntity>> call(Map<String, dynamic> body) {
    return repository.createCheckList(body);
  }
}
