import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/department_remote_data_source.dart';
import '../data/repositories/department_repository_impl.dart';
import '../domain/repositories/department_repository.dart';
import '../domain/usecases/create_department_usecase.dart';
import '../domain/usecases/get_department_overview_usecase.dart';
import '../domain/usecases/get_departments_usecase.dart';
import '../domain/usecases/get_leaf_departments_usecase.dart';
import '../domain/usecases/toggle_department_status_usecase.dart';
import '../presentation/bloc/departments_bloc.dart';

Future<void> setupDepartmentsInjection() async {
  if (!getIt.isRegistered<DepartmentRemoteDataSource>()) {
    getIt.registerLazySingleton<DepartmentRemoteDataSource>(
      () => DepartmentRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<DepartmentRepository>()) {
    getIt.registerLazySingleton<DepartmentRepository>(
      () => DepartmentRepositoryImpl(getIt<DepartmentRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetDepartmentsUseCase>()) {
    getIt.registerLazySingleton<GetDepartmentsUseCase>(
      () => GetDepartmentsUseCase(getIt<DepartmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetDepartmentOverviewUseCase>()) {
    getIt.registerLazySingleton<GetDepartmentOverviewUseCase>(
      () => GetDepartmentOverviewUseCase(getIt<DepartmentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetLeafDepartmentsUseCase>()) {
    getIt.registerLazySingleton<GetLeafDepartmentsUseCase>(
      () => GetLeafDepartmentsUseCase(getIt<DepartmentRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateDepartmentUseCase>()) {
    getIt.registerLazySingleton<CreateDepartmentUseCase>(
      () => CreateDepartmentUseCase(getIt<DepartmentRepository>()),
    );
  }

  if (!getIt.isRegistered<ToggleDepartmentStatusUseCase>()) {
    getIt.registerLazySingleton<ToggleDepartmentStatusUseCase>(
      () => ToggleDepartmentStatusUseCase(getIt<DepartmentRepository>()),
    );
  }

  getIt.registerFactory<DepartmentsBloc>(
    () => DepartmentsBloc(
      getDepartments: getIt<GetDepartmentsUseCase>(),
      getOverview: getIt<GetDepartmentOverviewUseCase>(),
      createDepartment: getIt<CreateDepartmentUseCase>(),
      toggleStatus: getIt<ToggleDepartmentStatusUseCase>(),
    ),
  );
}
