import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../active_org/active_organization_cubit.dart';
import '../services/key_generation_service.dart';
import '../network/dio_client.dart';
import '../services/key_storage_service.dart';
import '../services/api_service.dart';
import '../storage/secure_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupCoreInjection() async {
  // Storage must be registered before Dio: the AuthInterceptor depends on it.
  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(),
    );
  }

  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(
      () => DioClient.create(getIt<SecureStorageService>()),
    );
  }

  // The single network gateway shared by every feature's data source.
  if (!getIt.isRegistered<ApiService>()) {
    getIt.registerLazySingleton<ApiService>(
      () => ApiService(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<KeyGenerationService>()) {
    getIt.registerLazySingleton<KeyGenerationService>(
      () => KeyGenerationService(),
    );
  }

  if (!getIt.isRegistered<KeyStorageService>()) {
  getIt.registerLazySingleton<KeyStorageService>(
    () => KeyStorageService(),
  );
}

  // The single source of truth for the user's active organization. It resolves
  // GetInstitutionsUseCase lazily inside load(), so registration order relative
  // to setupInstitutionsInjection doesn't matter.
  if (!getIt.isRegistered<ActiveOrganizationCubit>()) {
    getIt.registerLazySingleton<ActiveOrganizationCubit>(
      () => ActiveOrganizationCubit(getIt<SecureStorageService>()),
    );
  }
}

 