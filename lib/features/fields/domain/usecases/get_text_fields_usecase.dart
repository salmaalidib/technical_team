import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/text_field_entity.dart';
import '../repositories/fields_repository.dart';

class GetTextFieldsUseCase {
  final FieldsRepository repository;

  GetTextFieldsUseCase(this.repository);

  Future<Either<Failure, List<TextFieldEntity>>> call() {
    return repository.getTextFields();
  }
}
