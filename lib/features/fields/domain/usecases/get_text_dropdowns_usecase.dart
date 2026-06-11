import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/text_dropdown_entity.dart';
import '../repositories/fields_repository.dart';

class GetTextDropdownsUseCase {
  final FieldsRepository repository;

  GetTextDropdownsUseCase(this.repository);

  Future<Either<Failure, List<TextDropdownEntity>>> call() {
    return repository.getTextDropdowns();
  }
}
