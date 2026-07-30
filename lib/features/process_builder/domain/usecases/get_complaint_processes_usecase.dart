import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_process_item.dart';
import '../repositories/process_builder_repository.dart';

/// `GET /api/process_definitions/admin/complaints/all` — all complaint
/// processes (active + inactive).
class GetComplaintProcessesUseCase {
  final ProcessBuilderRepository repository;

  GetComplaintProcessesUseCase(this.repository);

  Future<Either<Failure, List<AdminProcessItem>>> call({
    int page = 1,
    int limit = 100,
  }) {
    return repository.getComplaintProcesses(page: page, limit: limit);
  }
}
