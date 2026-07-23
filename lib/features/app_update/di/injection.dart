import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/injection.dart';
import '../data/datasources/app_update_remote_data_source.dart';
import '../data/repositories/app_update_repository_impl.dart';
import '../domain/repositories/app_update_repository.dart';
import '../domain/usecases/check_for_update_usecase.dart';
import '../presentation/bloc/app_update_bloc.dart';

Future<void> setupAppUpdateInjection() async {
  // pubspec.yaml: `version: X.Y.Z+N` → buildNumber هو رقم المقارنة الفعلي
  // (version_code)؛ يُقرأ مرة واحدة عند الإقلاع، وليس عبر ثابت مكتوب يدوياً
  // كي لا يُنسى تحديثه (انظر §5.2 من توثيق الميزة: هذا نفس فخ --split-per-abi
  // من ناحية "لا تعتمد على رقم مكتوب بخط اليد").
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

  if (!getIt.isRegistered<AppUpdateRemoteDataSource>()) {
    getIt.registerLazySingleton<AppUpdateRemoteDataSource>(
      () => AppUpdateRemoteDataSource(),
    );
  }

  if (!getIt.isRegistered<AppUpdateRepository>()) {
    getIt.registerLazySingleton<AppUpdateRepository>(
      () => AppUpdateRepositoryImpl(getIt<AppUpdateRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<CheckForUpdateUseCase>()) {
    getIt.registerLazySingleton<CheckForUpdateUseCase>(
      () => CheckForUpdateUseCase(getIt<AppUpdateRepository>()),
    );
  }

  // Singleton (لا factory): يجب أن تبقى نفس نسخة البلوك حية من splash وحتى
  // شاشة settings — لو أُعيد إنشاؤها لكل شاشة لَفَقَدنا حالة "جارٍ التحميل"
  // عند التنقّل بعيداً عن ForceUpdatePage أثناء تنزيل مستمر في الخلفية.
  if (!getIt.isRegistered<AppUpdateBloc>()) {
    getIt.registerLazySingleton<AppUpdateBloc>(
      () => AppUpdateBloc(
        checkForUpdate: getIt<CheckForUpdateUseCase>(),
        remote: getIt<AppUpdateRemoteDataSource>(),
        currentVersionCode: currentVersionCode,
      ),
    );
  }
}
