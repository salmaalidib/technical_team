import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/type_doc_remote_data_source.dart';
import '../data/repositories/type_doc_repository_impl.dart';
import '../domain/repositories/type_doc_repository.dart';
import '../domain/usecases/create_type_doc_usecase.dart';
import '../domain/usecases/get_type_docs_usecase.dart';
import '../domain/usecases/update_type_doc_usecase.dart';
import '../presentation/bloc/type_docs_bloc.dart';

Future<void> setupTypeDocsInjection() async {
  if (!getIt.isRegistered<TypeDocRemoteDataSource>()) {
    getIt.registerLazySingleton<TypeDocRemoteDataSource>(
      () => TypeDocRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<TypeDocRepository>()) {
    getIt.registerLazySingleton<TypeDocRepository>(
      () => TypeDocRepositoryImpl(getIt<TypeDocRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTypeDocsUseCase>()) {
    getIt.registerLazySingleton<GetTypeDocsUseCase>(
      () => GetTypeDocsUseCase(getIt<TypeDocRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateTypeDocUseCase>()) {
    getIt.registerLazySingleton<CreateTypeDocUseCase>(
      () => CreateTypeDocUseCase(getIt<TypeDocRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateTypeDocUseCase>()) {
    getIt.registerLazySingleton<UpdateTypeDocUseCase>(
      () => UpdateTypeDocUseCase(getIt<TypeDocRepository>()),
    );
  }

  getIt.registerFactory<TypeDocsBloc>(
    () => TypeDocsBloc(
      getTypeDocs: getIt<GetTypeDocsUseCase>(),
      createTypeDoc: getIt<CreateTypeDocUseCase>(),
      updateTypeDoc: getIt<UpdateTypeDocUseCase>(),
    ),
  );
}
