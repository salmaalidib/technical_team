import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/file_picker_entity.dart';
import '../repositories/fields_repository.dart';

class CreateFilePickerUseCase {
  final FieldsRepository repository;

  CreateFilePickerUseCase(this.repository);

  Future<Either<Failure, FilePickerEntity>> call(Map<String, dynamic> body) {
    return repository.createFilePicker(body);
  }
}
