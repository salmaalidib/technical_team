import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/type_process_remote_data_source.dart';
import '../data/repositories/type_process_repository_impl.dart';
import '../domain/repositories/type_process_repository.dart';
import '../domain/usecases/create_type_process_usecase.dart';
import '../domain/usecases/get_type_processes_usecase.dart';
import '../domain/usecases/update_type_process_status_usecase.dart';
import '../presentation/bloc/type_processes_bloc.dart';

Future<void> setupTypeProcessesInjection() async {
  if (!getIt.isRegistered<TypeProcessRemoteDataSource>()) {
    getIt.registerLazySingleton<TypeProcessRemoteDataSource>(
      () => TypeProcessRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<TypeProcessRepository>()) {
    getIt.registerLazySingleton<TypeProcessRepository>(
      () => TypeProcessRepositoryImpl(getIt<TypeProcessRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTypeProcessesUseCase>()) {
    getIt.registerLazySingleton<GetTypeProcessesUseCase>(
      () => GetTypeProcessesUseCase(getIt<TypeProcessRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateTypeProcessUseCase>()) {
    getIt.registerLazySingleton<CreateTypeProcessUseCase>(
      () => CreateTypeProcessUseCase(getIt<TypeProcessRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateTypeProcessStatusUseCase>()) {
    getIt.registerLazySingleton<UpdateTypeProcessStatusUseCase>(
      () => UpdateTypeProcessStatusUseCase(getIt<TypeProcessRepository>()),
    );
  }

  getIt.registerFactory<TypeProcessesBloc>(
    () => TypeProcessesBloc(
      getTypeProcesses: getIt<GetTypeProcessesUseCase>(),
      createTypeProcess: getIt<CreateTypeProcessUseCase>(),
      updateStatus: getIt<UpdateTypeProcessStatusUseCase>(),
    ),
  );
}
