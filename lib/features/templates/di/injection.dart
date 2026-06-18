import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/doc_template_remote_data_source.dart';
import '../data/repositories/doc_template_repository_impl.dart';
import '../domain/repositories/doc_template_repository.dart';
import '../domain/usecases/create_template_usecase.dart';
import '../domain/usecases/get_template_usecase.dart';
import '../domain/usecases/get_templates_usecase.dart';
import '../domain/usecases/update_template_usecase.dart';
import '../presentation/bloc/templates_bloc.dart';

/// Registers the document-templates feature. The file-picker widget editor
/// reuses [TypeDocsBloc] (provided at the page level), so run this after
/// `setupTypeDocsInjection()`.
Future<void> setupTemplatesInjection() async {
  if (!getIt.isRegistered<DocTemplateRemoteDataSource>()) {
    getIt.registerLazySingleton<DocTemplateRemoteDataSource>(
      () => DocTemplateRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<DocTemplateRepository>()) {
    getIt.registerLazySingleton<DocTemplateRepository>(
      () => DocTemplateRepositoryImpl(getIt<DocTemplateRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTemplatesUseCase>()) {
    getIt.registerLazySingleton<GetTemplatesUseCase>(
      () => GetTemplatesUseCase(getIt<DocTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTemplateUseCase>()) {
    getIt.registerLazySingleton<GetTemplateUseCase>(
      () => GetTemplateUseCase(getIt<DocTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateTemplateUseCase>()) {
    getIt.registerLazySingleton<CreateTemplateUseCase>(
      () => CreateTemplateUseCase(getIt<DocTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateTemplateUseCase>()) {
    getIt.registerLazySingleton<UpdateTemplateUseCase>(
      () => UpdateTemplateUseCase(getIt<DocTemplateRepository>()),
    );
  }

  getIt.registerFactory<TemplatesBloc>(
    () => TemplatesBloc(
      getTemplates: getIt<GetTemplatesUseCase>(),
      createTemplate: getIt<CreateTemplateUseCase>(),
      updateTemplate: getIt<UpdateTemplateUseCase>(),
    ),
  );
}
