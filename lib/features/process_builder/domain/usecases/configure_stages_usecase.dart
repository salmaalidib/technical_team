import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/process_builder_repository.dart';

class ConfigureStagesUseCase {
  final ProcessBuilderRepository repository;

  ConfigureStagesUseCase(this.repository);

  Future<Either<Failure, void>> call(List<Map<String, dynamic>> stages) {
    return repository.configureStages(stages);
  }
}
