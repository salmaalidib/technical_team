import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/text_field_entity.dart';
import '../repositories/fields_repository.dart';

class CreateTextFieldUseCase {
  final FieldsRepository repository;

  CreateTextFieldUseCase(this.repository);

  Future<Either<Failure, TextFieldEntity>> call(Map<String, dynamic> body) {
    return repository.createTextField(body);
  }
}
