import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/date_picker_entity.dart';
import '../repositories/fields_repository.dart';

class GetDatePickersUseCase {
  final FieldsRepository repository;

  GetDatePickersUseCase(this.repository);

  Future<Either<Failure, Paginated<DatePickerEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getDatePickers(page: page, limit: limit, search: search);
  }
}
