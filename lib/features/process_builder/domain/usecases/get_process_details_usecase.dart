import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/process_details.dart';
import '../repositories/process_builder_repository.dart';

class GetProcessDetailsUseCase {
  final ProcessBuilderRepository repository;

  GetProcessDetailsUseCase(this.repository);

  Future<Either<Failure, ProcessDetails>> call(int id) {
    return repository.getProcessDetails(id);
  }
}
