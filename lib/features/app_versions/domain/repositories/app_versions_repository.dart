import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_version_row.dart';
import '../entities/managed_application.dart';

abstract class AppVersionsRepository {
  Future<Either<Failure, List<ManagedApplication>>> getApplications();

  Future<Either<Failure, ManagedApplication>> updateApplication({
    required int appId,
    required Map<String, dynamic> body,
  });

  Future<Either<Failure, List<AppVersionRow>>> getVersions(int appId);

  Future<Either<Failure, AppVersionRow>> createVersion({
    required int appId,
    required Map<String, dynamic> body,
  });

  Future<Either<Failure, AppVersionRow>> updateVersion({
    required int appId,
    required int versionId,
    required Map<String, dynamic> body,
  });

  Future<Either<Failure, Unit>> deleteVersion({
    required int appId,
    required int versionId,
  });
}
