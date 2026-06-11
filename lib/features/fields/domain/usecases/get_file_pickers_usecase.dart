import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/file_picker_entity.dart';
import '../repositories/fields_repository.dart';

class GetFilePickersUseCase {
  final FieldsRepository repository;

  GetFilePickersUseCase(this.repository);

  Future<Either<Failure, List<FilePickerEntity>>> call() {
    return repository.getFilePickers();
  }
}
