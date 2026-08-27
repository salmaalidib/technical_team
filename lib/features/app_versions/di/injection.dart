import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';
import '../data/datasources/app_versions_remote_data_source.dart';
import '../data/repositories/app_versions_repository_impl.dart';
import '../domain/repositories/app_versions_repository.dart';
import '../domain/usecases/app_versions_usecases.dart';
import '../presentation/bloc/app_versions_bloc.dart';

/// إدارة إصدارات التطبيقات الثلاثة (أدمن). منفصلة تماماً عن
/// `setupAppUpdateInjection` التي تخصّ *استهلاك* التحديث في هذا التطبيق نفسه.
Future<void> setupAppVersionsInjection() async {
  if (!getIt.isRegistered<AppVersionsRemoteDataSource>()) {
    getIt.registerLazySingleton<AppVersionsRemoteDataSource>(
      () => AppVersionsRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<AppVersionsRepository>()) {
    getIt.registerLazySingleton<AppVersionsRepository>(
      () => AppVersionsRepositoryImpl(getIt<AppVersionsRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetApplicationsUseCase>()) {
    getIt.registerLazySingleton<GetApplicationsUseCase>(
      () => GetApplicationsUseCase(getIt<AppVersionsRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateApplicationUseCase>()) {
    getIt.registerLazySingleton<UpdateApplicationUseCase>(
      () => UpdateApplicationUseCase(getIt<AppVersionsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetVersionsUseCase>()) {
    getIt.registerLazySingleton<GetVersionsUseCase>(
      () => GetVersionsUseCase(getIt<AppVersionsRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateVersionUseCase>()) {
    getIt.registerLazySingleton<CreateVersionUseCase>(
      () => CreateVersionUseCase(getIt<AppVersionsRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateVersionUseCase>()) {
    getIt.registerLazySingleton<UpdateVersionUseCase>(
      () => UpdateVersionUseCase(getIt<AppVersionsRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteVersionUseCase>()) {
    getIt.registerLazySingleton<DeleteVersionUseCase>(
      () => DeleteVersionUseCase(getIt<AppVersionsRepository>()),
    );
  }

  // factory لا singleton: الشاشة تُنشئ البلوك عند فتحها وتتخلّص منه عند
  // مغادرتها — لا حالة يجب أن تبقى حيّة بعد الخروج، على خلاف AppUpdateBloc.
  if (!getIt.isRegistered<AppVersionsBloc>()) {
    getIt.registerFactory<AppVersionsBloc>(
      () => AppVersionsBloc(
        getApplications: getIt<GetApplicationsUseCase>(),
        updateApplication: getIt<UpdateApplicationUseCase>(),
        getVersions: getIt<GetVersionsUseCase>(),
        createVersion: getIt<CreateVersionUseCase>(),
        updateVersion: getIt<UpdateVersionUseCase>(),
        deleteVersion: getIt<DeleteVersionUseCase>(),
      ),
    );
  }
}
