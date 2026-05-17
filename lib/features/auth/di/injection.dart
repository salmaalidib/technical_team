import 'package:get_it/get_it.dart';
import 'package:technical_team/core/storage/secure_storage_service.dart';

import '../../../core/network/dio_client.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';

import '../domain/repositories/auth_repository.dart';

import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/verify_otp_usecase.dart';

import '../presentation/bloc/login/login_bloc.dart';
import '../presentation/bloc/otp/otp_bloc.dart';
final getIt = GetIt.instance;

Future<void> setupLoginInjection() async {
  getIt.registerLazySingleton(() => DioClient.create());

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(
    () => LoginUseCase(getIt()),
  );

  getIt.registerLazySingleton(
    () => VerifyOtpUseCase(getIt()),
  );

  getIt.registerLazySingleton(
    () => SecureStorageService(),
  );

  getIt.registerFactory(
    () => LoginBloc(getIt()),
  );

  getIt.registerFactory(
    () => OtpBloc(
      getIt(),
      getIt(),
    ),
  );
}