import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/field_remote_data_source.dart';
import '../data/datasources/file_remote_data_source.dart';
import '../data/repositories/field_repository_impl.dart';
import '../data/repositories/file_repository_impl.dart';
import '../domain/repositories/field_repository.dart';
import '../domain/repositories/file_repository.dart';
import '../domain/usecases/get_fields_usecase.dart';
import '../domain/usecases/get_files_usecase.dart';
import '../domain/usecases/save_field_usecase.dart';
import '../domain/usecases/save_file_usecase.dart';
import '../presentation/bloc/fields_bloc.dart';
import '../presentation/bloc/files_bloc.dart';

Future<void> setupFieldsInjection() async {
  // ===== dynamic fields =====
  if (!getIt.isRegistered<FieldRemoteDataSource>()) {
    getIt.registerLazySingleton<FieldRemoteDataSource>(
      () => FieldRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<FieldRepository>()) {
    getIt.registerLazySingleton<FieldRepository>(
      () => FieldRepositoryImpl(getIt<FieldRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetFieldsUseCase>()) {
    getIt.registerLazySingleton<GetFieldsUseCase>(
      () => GetFieldsUseCase(getIt<FieldRepository>()),
    );
  }

  if (!getIt.isRegistered<SaveFieldUseCase>()) {
    getIt.registerLazySingleton<SaveFieldUseCase>(
      () => SaveFieldUseCase(getIt<FieldRepository>()),
    );
  }

  getIt.registerFactory<FieldsBloc>(
    () => FieldsBloc(
      getFields: getIt<GetFieldsUseCase>(),
      saveField: getIt<SaveFieldUseCase>(),
    ),
  );

  // ===== file definitions =====
  if (!getIt.isRegistered<FileRemoteDataSource>()) {
    getIt.registerLazySingleton<FileRemoteDataSource>(
      () => FileRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<FileRepository>()) {
    getIt.registerLazySingleton<FileRepository>(
      () => FileRepositoryImpl(getIt<FileRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetFilesUseCase>()) {
    getIt.registerLazySingleton<GetFilesUseCase>(
      () => GetFilesUseCase(getIt<FileRepository>()),
    );
  }

  if (!getIt.isRegistered<SaveFileUseCase>()) {
    getIt.registerLazySingleton<SaveFileUseCase>(
      () => SaveFileUseCase(getIt<FileRepository>()),
    );
  }

  getIt.registerFactory<FilesBloc>(
    () => FilesBloc(
      getFiles: getIt<GetFilesUseCase>(),
      saveFile: getIt<SaveFileUseCase>(),
    ),
  );
}
