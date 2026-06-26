import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../data/datasources/role_remote_data_source.dart';
import '../data/repositories/role_repository_impl.dart';
import '../domain/repositories/role_repository.dart';
import '../domain/usecases/create_role_usecase.dart';
import '../domain/usecases/get_roles_by_department_usecase.dart';
import '../domain/usecases/get_roles_usecase.dart';
import '../domain/usecases/toggle_role_status_usecase.dart';
import '../presentation/bloc/roles_bloc.dart';

/// Must run after `setupDepartmentsInjection` because [RolesBloc] reuses its
/// leaf-departments use case. The active organization comes from the central
/// `ActiveOrganizationCubit`, not from a per-feature org fetch.
Future<void> setupRolesInjection() async {
  if (!getIt.isRegistered<RoleRemoteDataSource>()) {
    getIt.registerLazySingleton<RoleRemoteDataSource>(
      () => RoleRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<RoleRepository>()) {
    getIt.registerLazySingleton<RoleRepository>(
      () => RoleRepositoryImpl(getIt<RoleRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetRolesUseCase>()) {
    getIt.registerLazySingleton<GetRolesUseCase>(
      () => GetRolesUseCase(getIt<RoleRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateRoleUseCase>()) {
    getIt.registerLazySingleton<CreateRoleUseCase>(
      () => CreateRoleUseCase(getIt<RoleRepository>()),
    );
  }

  if (!getIt.isRegistered<ToggleRoleStatusUseCase>()) {
    getIt.registerLazySingleton<ToggleRoleStatusUseCase>(
      () => ToggleRoleStatusUseCase(getIt<RoleRepository>()),
    );
  }

  if (!getIt.isRegistered<GetRolesByDepartmentUseCase>()) {
    getIt.registerLazySingleton<GetRolesByDepartmentUseCase>(
      () => GetRolesByDepartmentUseCase(getIt<RoleRepository>()),
    );
  }

  getIt.registerFactory<RolesBloc>(
    () => RolesBloc(
      getRoles: getIt<GetRolesUseCase>(),
      createRole: getIt<CreateRoleUseCase>(),
      toggleStatus: getIt<ToggleRoleStatusUseCase>(),
      getLeafDepartments: getIt<GetLeafDepartmentsUseCase>(),
      getRolesByDepartment: getIt<GetRolesByDepartmentUseCase>(),
    ),
  );
}
