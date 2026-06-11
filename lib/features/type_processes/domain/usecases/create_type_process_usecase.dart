import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_process.dart';
import '../repositories/type_process_repository.dart';

class CreateTypeProcessUseCase {
  final TypeProcessRepository repository;

  CreateTypeProcessUseCase(this.repository);

  Future<Either<Failure, TypeProcess>> call({required String name}) {
    return repository.createTypeProcess(name: name);
  }
}
