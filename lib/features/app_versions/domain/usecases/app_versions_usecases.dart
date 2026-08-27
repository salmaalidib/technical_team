import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_version_row.dart';
import '../entities/managed_application.dart';
import '../repositories/app_versions_repository.dart';

/// حالات الاستخدام الست لإدارة الإصدارات. مجمّعة في ملف واحد لأن كلاً منها
/// تمريرة واحدة إلى المستودع بلا منطق خاص — تقسيمها إلى ستة ملفات كان سيضيف
/// ضجيجاً بلا فائدة.
class GetApplicationsUseCase {
  final AppVersionsRepository repository;
  GetApplicationsUseCase(this.repository);

  Future<Either<Failure, List<ManagedApplication>>> call() =>
      repository.getApplications();
}

class UpdateApplicationUseCase {
  final AppVersionsRepository repository;
  UpdateApplicationUseCase(this.repository);

  Future<Either<Failure, ManagedApplication>> call({
    required int appId,
    required Map<String, dynamic> body,
  }) =>
      repository.updateApplication(appId: appId, body: body);
}

class GetVersionsUseCase {
  final AppVersionsRepository repository;
  GetVersionsUseCase(this.repository);

  Future<Either<Failure, List<AppVersionRow>>> call(int appId) =>
      repository.getVersions(appId);
}

class CreateVersionUseCase {
  final AppVersionsRepository repository;
  CreateVersionUseCase(this.repository);

  Future<Either<Failure, AppVersionRow>> call({
    required int appId,
    required Map<String, dynamic> body,
  }) =>
      repository.createVersion(appId: appId, body: body);
}

class UpdateVersionUseCase {
  final AppVersionsRepository repository;
  UpdateVersionUseCase(this.repository);

  Future<Either<Failure, AppVersionRow>> call({
    required int appId,
    required int versionId,
    required Map<String, dynamic> body,
  }) =>
      repository.updateVersion(appId: appId, versionId: versionId, body: body);
}

class DeleteVersionUseCase {
  final AppVersionsRepository repository;
  DeleteVersionUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required int appId,
    required int versionId,
  }) =>
      repository.deleteVersion(appId: appId, versionId: versionId);
}
