import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/radio_group_entity.dart';
import '../repositories/fields_repository.dart';

class GetRadioGroupsUseCase {
  final FieldsRepository repository;

  GetRadioGroupsUseCase(this.repository);

  Future<Either<Failure, List<RadioGroupEntity>>> call() {
    return repository.getRadioGroups();
  }
}
