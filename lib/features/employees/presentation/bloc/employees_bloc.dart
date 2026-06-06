import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../../roles/domain/usecases/get_roles_by_department_usecase.dart';
import '../../domain/usecases/create_employee_usecase.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final CreateEmployeeUseCase createEmployee;

  final GetInstitutionsUseCase getOrganizations;
  final GetLeafDepartmentsUseCase getLeafDepartments;
  final GetRolesByDepartmentUseCase getRolesByDepartment;

  EmployeesBloc({
    required this.createEmployee,
    required this.getOrganizations,
    required this.getLeafDepartments,
    required this.getRolesByDepartment,
  }) : super(const EmployeesState()) {
    on<LoadEmployeeFormData>(_onLoadFormData);
    on<LoadEmployeeDepartments>(_onLoadDepartments);
    on<LoadEmployeeRoles>(_onLoadRoles);
    on<CreateEmployeeRequested>(_onCreate);
  }

  Future<void> _onLoadFormData(
    LoadEmployeeFormData event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(state.copyWith(
      organizationsStatus: RequestStatus.loading,
      actionError: null,
    ));

    final result = await getOrganizations();

    result.fold(
      (failure) => emit(state.copyWith(
        organizationsStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (organizations) => emit(state.copyWith(
        organizationsStatus: RequestStatus.success,
        organizations: organizations,
      )),
    );
  }

  Future<void> _onLoadDepartments(
    LoadEmployeeDepartments event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(state.copyWith(
      departmentsStatus: RequestStatus.loading,
      departments: const [],
      roles: const [],
      actionError: null,
    ));

    final result = await getLeafDepartments(event.organizationId);

    result.fold(
      (failure) => emit(state.copyWith(
        departmentsStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (departments) => emit(state.copyWith(
        departmentsStatus: RequestStatus.success,
        departments: departments,
      )),
    );
  }

  Future<void> _onLoadRoles(
    LoadEmployeeRoles event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(state.copyWith(
      rolesStatus: RequestStatus.loading,
      roles: const [],
      actionError: null,
    ));

    final result = await getRolesByDepartment(event.departmentId);

    result.fold(
      (failure) => emit(state.copyWith(
        rolesStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (roles) => emit(state.copyWith(
        rolesStatus: RequestStatus.success,
        roles: roles,
      )),
    );
  }

  Future<void> _onCreate(
    CreateEmployeeRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createEmployee(
      firstName: event.firstName,
      lastName: event.lastName,
      fatherName: event.fatherName,
      motherName: event.motherName,
      nationalId: event.nationalId,
      userName: event.userName,
      email: event.email,
      phoneNumber: event.phoneNumber,
      password: event.password,
      pin: event.pin,
      confirmPin: event.confirmPin,
      organizationId: event.organizationId,
      departmentId: event.departmentId,
      roleId: event.roleId,
      publicKey: event.publicKey,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (createdEmployee) => emit(state.copyWith(
        formStatus: FormStatus.success,
        createdEmployee: createdEmployee,
      )),
    );
  }
}