import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_process.dart';
import '../repositories/type_process_repository.dart';

class UpdateTypeProcessStatusUseCase {
  final TypeProcessRepository repository;

  UpdateTypeProcessStatusUseCase(this.repository);

  Future<Either<Failure, TypeProcess>> call({
    required int id,
    required bool isActive,
  }) {
    return repository.updateStatus(id: id, isActive: isActive);
  }
}
