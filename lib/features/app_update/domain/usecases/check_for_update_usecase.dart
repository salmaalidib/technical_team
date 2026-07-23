import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_update_info.dart';
import '../repositories/app_update_repository.dart';

class CheckForUpdateUseCase {
  final AppUpdateRepository repository;

  CheckForUpdateUseCase(this.repository);

  Future<Either<Failure, UpdateCheckResult>> call({
    required int currentVersionCode,
  }) {
    return repository.checkForUpdate(currentVersionCode: currentVersionCode);
  }
}
