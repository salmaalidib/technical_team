import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../roles/domain/usecases/get_roles_by_department_usecase.dart';
import '../../type_processes/domain/usecases/get_type_processes_usecase.dart';
import '../data/datasources/process_builder_remote_data_source.dart';
import '../data/repositories/process_builder_repository_impl.dart';
import '../domain/repositories/process_builder_repository.dart';
import '../domain/usecases/configure_stages_usecase.dart';
import '../domain/usecases/create_process_definition_usecase.dart';
import '../domain/usecases/get_process_details_usecase.dart';
import '../domain/usecases/get_processes_by_type_usecase.dart';
import '../domain/usecases/get_review_queue_usecase.dart';
import '../presentation/bloc/process_builder_bloc.dart';
import '../presentation/bloc/process_list_bloc.dart';

/// Must run AFTER institutions / departments / roles / type_processes injection,
/// because [ProcessBuilderBloc] reuses their use cases (the field library is
/// owned by FieldsBloc, provided separately at the page level).
Future<void> setupProcessBuilderInjection() async {
  if (!getIt.isRegistered<ProcessBuilderRemoteDataSource>()) {
    getIt.registerLazySingleton<ProcessBuilderRemoteDataSource>(
      () => ProcessBuilderRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<ProcessBuilderRepository>()) {
    getIt.registerLazySingleton<ProcessBuilderRepository>(
      () => ProcessBuilderRepositoryImpl(
        getIt<ProcessBuilderRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<CreateProcessDefinitionUseCase>()) {
    getIt.registerLazySingleton<CreateProcessDefinitionUseCase>(
      () => CreateProcessDefinitionUseCase(getIt<ProcessBuilderRepository>()),
    );
  }

  if (!getIt.isRegistered<ConfigureStagesUseCase>()) {
    getIt.registerLazySingleton<ConfigureStagesUseCase>(
      () => ConfigureStagesUseCase(getIt<ProcessBuilderRepository>()),
    );
  }

  if (!getIt.isRegistered<GetProcessesByTypeUseCase>()) {
    getIt.registerLazySingleton<GetProcessesByTypeUseCase>(
      () => GetProcessesByTypeUseCase(getIt<ProcessBuilderRepository>()),
    );
  }

  if (!getIt.isRegistered<GetReviewQueueUseCase>()) {
    getIt.registerLazySingleton<GetReviewQueueUseCase>(
      () => GetReviewQueueUseCase(getIt<ProcessBuilderRepository>()),
    );
  }

  if (!getIt.isRegistered<GetProcessDetailsUseCase>()) {
    getIt.registerLazySingleton<GetProcessDetailsUseCase>(
      () => GetProcessDetailsUseCase(getIt<ProcessBuilderRepository>()),
    );
  }

  getIt.registerFactory<ProcessBuilderBloc>(
    () => ProcessBuilderBloc(
      createProcess: getIt<CreateProcessDefinitionUseCase>(),
      configureStages: getIt<ConfigureStagesUseCase>(),
      getTypeProcesses: getIt<GetTypeProcessesUseCase>(),
      getOrganizations: getIt<GetInstitutionsUseCase>(),
      getLeafDepartments: getIt<GetLeafDepartmentsUseCase>(),
      getRolesByDepartment: getIt<GetRolesByDepartmentUseCase>(),
    ),
  );

  getIt.registerFactory<ProcessListBloc>(
    () => ProcessListBloc(
      getProcessesByType: getIt<GetProcessesByTypeUseCase>(),
      getReviewQueue: getIt<GetReviewQueueUseCase>(),
      getProcessDetails: getIt<GetProcessDetailsUseCase>(),
    ),
  );
}
