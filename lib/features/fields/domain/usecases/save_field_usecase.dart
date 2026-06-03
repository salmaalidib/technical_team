import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/field_repository.dart';

/// Creates a field when [id] is null, otherwise updates the existing one.
class SaveFieldUseCase {
  final FieldRepository repository;

  SaveFieldUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    int? id,
    required String name,
    required String type,
    List<String>? listValues,
  }) {
    if (id == null) {
      return repository.createField(
        name: name,
        type: type,
        listValues: listValues,
      );
    }
    return repository.updateField(
      id: id,
      name: name,
      type: type,
      listValues: listValues,
    );
  }
}
