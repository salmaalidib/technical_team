import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dynamic_field.dart';
import '../repositories/field_repository.dart';

class GetFieldsUseCase {
  final FieldRepository repository;

  GetFieldsUseCase(this.repository);

  Future<Either<Failure, List<DynamicField>>> call() {
    return repository.getFields();
  }
}
