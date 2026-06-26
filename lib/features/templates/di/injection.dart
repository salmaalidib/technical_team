import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/doc_template_remote_data_source.dart';
import '../data/repositories/doc_template_repository_impl.dart';
import '../domain/repositories/doc_template_repository.dart';
import '../domain/usecases/create_template_usecase.dart';
import '../domain/usecases/extract_fields_from_upload_usecase.dart';
import '../domain/usecases/extract_template_fields_usecase.dart';
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

  if (!getIt.isRegistered<ExtractTemplateFieldsUseCase>()) {
    getIt.registerLazySingleton<ExtractTemplateFieldsUseCase>(
      () => ExtractTemplateFieldsUseCase(getIt<DocTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<ExtractFieldsFromUploadUseCase>()) {
    getIt.registerLazySingleton<ExtractFieldsFromUploadUseCase>(
      () => ExtractFieldsFromUploadUseCase(getIt<DocTemplateRepository>()),
    );
  }

  getIt.registerFactory<TemplatesBloc>(
    () => TemplatesBloc(
      getTemplates: getIt<GetTemplatesUseCase>(),
      createTemplate: getIt<CreateTemplateUseCase>(),
      updateTemplate: getIt<UpdateTemplateUseCase>(),
      extractFields: getIt<ExtractTemplateFieldsUseCase>(),
      extractFieldsFromUpload: getIt<ExtractFieldsFromUploadUseCase>(),
    ),
  );
}
