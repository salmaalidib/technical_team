import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/radio_group_entity.dart';
import '../repositories/fields_repository.dart';

class CreateRadioGroupUseCase {
  final FieldsRepository repository;

  CreateRadioGroupUseCase(this.repository);

  Future<Either<Failure, RadioGroupEntity>> call(Map<String, dynamic> body) {
    return repository.createRadioGroup(body);
  }
}
