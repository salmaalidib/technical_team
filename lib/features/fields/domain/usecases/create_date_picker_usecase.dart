import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/date_picker_entity.dart';
import '../repositories/fields_repository.dart';

class CreateDatePickerUseCase {
  final FieldsRepository repository;

  CreateDatePickerUseCase(this.repository);

  Future<Either<Failure, DatePickerEntity>> call(Map<String, dynamic> body) {
    return repository.createDatePicker(body);
  }
}
