import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../roles/domain/usecases/get_roles_by_department_usecase.dart';

import '../data/datasources/employee_remote_data_source.dart';
import '../data/repositories/employee_repository_impl.dart';
import '../domain/repositories/employee_repository.dart';
import '../domain/usecases/create_employee_usecase.dart';
import '../presentation/bloc/employees_bloc.dart';

Future<void> setupEmployeesInjection() async {
  if (!getIt.isRegistered<EmployeeRemoteDataSource>()) {
    getIt.registerLazySingleton<EmployeeRemoteDataSource>(
      () => EmployeeRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<EmployeeRepository>()) {
    getIt.registerLazySingleton<EmployeeRepository>(
      () => EmployeeRepositoryImpl(getIt<EmployeeRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<CreateEmployeeUseCase>()) {
    getIt.registerLazySingleton<CreateEmployeeUseCase>(
      () => CreateEmployeeUseCase(getIt<EmployeeRepository>()),
    );
  }

  getIt.registerFactory<EmployeesBloc>(
    () => EmployeesBloc(
      createEmployee: getIt<CreateEmployeeUseCase>(),
      getOrganizations: getIt<GetInstitutionsUseCase>(),
      getLeafDepartments: getIt<GetLeafDepartmentsUseCase>(),
      getRolesByDepartment: getIt<GetRolesByDepartmentUseCase>(),
    ),
  );
}