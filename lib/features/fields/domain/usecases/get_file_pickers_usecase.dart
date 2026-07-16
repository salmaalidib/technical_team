import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/file_picker_entity.dart';
import '../repositories/fields_repository.dart';

class GetFilePickersUseCase {
  final FieldsRepository repository;

  GetFilePickersUseCase(this.repository);

  Future<Either<Failure, Paginated<FilePickerEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getFilePickers(page: page, limit: limit, search: search);
  }
}
