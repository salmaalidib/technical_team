import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_process_item.dart';
import '../repositories/process_builder_repository.dart';

class GetProcessesByTypeUseCase {
  final ProcessBuilderRepository repository;

  GetProcessesByTypeUseCase(this.repository);

  Future<Either<Failure, List<AdminProcessItem>>> call({
    int typeId = 0,
    int page = 1,
    int limit = 100,
  }) {
    return repository.getProcessesByType(
      typeId: typeId,
      page: page,
      limit: limit,
    );
  }
}
