import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_process.dart';
import '../repositories/type_process_repository.dart';

class GetTypeProcessesUseCase {
  final TypeProcessRepository repository;

  GetTypeProcessesUseCase(this.repository);

  Future<Either<Failure, List<TypeProcess>>> call() {
    return repository.getTypeProcesses();
  }
}
