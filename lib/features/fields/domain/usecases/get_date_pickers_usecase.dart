import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/date_picker_entity.dart';
import '../repositories/fields_repository.dart';

class GetDatePickersUseCase {
  final FieldsRepository repository;

  GetDatePickersUseCase(this.repository);

  Future<Either<Failure, List<DatePickerEntity>>> call() {
    return repository.getDatePickers();
  }
}
