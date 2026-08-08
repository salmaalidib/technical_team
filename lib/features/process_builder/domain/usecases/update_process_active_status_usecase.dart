import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/process_builder_repository.dart';

/// `PATCH /api/process_definitions/admin/{id}/status` — flips `is_active` for a
/// process, moving it between the "فعّالة" and "غير فعّالة" tabs of a type.
class UpdateProcessActiveStatusUseCase {
  final ProcessBuilderRepository repository;

  UpdateProcessActiveStatusUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int id,
    required bool isActive,
  }) =>
      repository.updateProcessActiveStatus(id: id, isActive: isActive);
}
