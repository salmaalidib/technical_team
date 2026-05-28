import 'package:dio/dio.dart';

import '../../../core/di/injection.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/verify_otp_usecase.dart';

import '../presentation/bloc/login/login_bloc.dart';
import '../presentation/bloc/otp/otp_bloc.dart';

import '../../../core/storage/secure_storage_service.dart';

Future<void> setupAuthInjection() async {
  if (!getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<VerifyOtpUseCase>()) {
    getIt.registerLazySingleton<VerifyOtpUseCase>(
      () => VerifyOtpUseCase(getIt<AuthRepository>()),
    );
  }

  getIt.registerFactory<LoginBloc>(
    () => LoginBloc(getIt<LoginUseCase>()),
  );

  getIt.registerFactory<OtpBloc>(
    () => OtpBloc(
      getIt<VerifyOtpUseCase>(),
      getIt<SecureStorageService>(),
    ),
  );
}