import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/text_dropdown_entity.dart';
import '../repositories/fields_repository.dart';

class CreateTextDropdownUseCase {
  final FieldsRepository repository;

  CreateTextDropdownUseCase(this.repository);

  Future<Either<Failure, TextDropdownEntity>> call(Map<String, dynamic> body) {
    return repository.createTextDropdown(body);
  }
}
