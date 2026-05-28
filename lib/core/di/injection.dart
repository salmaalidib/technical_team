import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupCoreInjection() async {
  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(
      () => DioClient.create(),
    );
  }

  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(),
    );
  }
}