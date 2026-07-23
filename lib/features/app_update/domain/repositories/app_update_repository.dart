import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_update_info.dart';

abstract class AppUpdateRepository {
  Future<Either<Failure, UpdateCheckResult>> checkForUpdate({
    required int currentVersionCode,
  });
}
