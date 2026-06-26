import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../../roles/domain/usecases/get_roles_by_department_usecase.dart';
import '../../domain/usecases/create_employee_usecase.dart';
import '../../domain/usecases/get_employees_usecase.dart';
import '../../domain/usecases/update_employee_usecase.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final CreateEmployeeUseCase createEmployee;
  final GetEmployeesUseCase getEmployees;
  final UpdateEmployeeUseCase updateEmployee;

  final GetLeafDepartmentsUseCase getLeafDepartments;
  final GetRolesByDepartmentUseCase getRolesByDepartment;

  EmployeesBloc({
    required this.createEmployee,
    required this.getEmployees,
    required this.updateEmployee,
    required this.getLeafDepartments,
    required this.getRolesByDepartment,
  }) : super(const EmployeesState()) {
    on<LoadEmployees>(_onLoadEmployees);
    on<SearchEmployees>(_onSearch);
    on<UpdateEmployeeRequested>(_onUpdate);
    on<ResetEmployeeFormStatus>(_onResetFormStatus);
    on<LoadEmployeeDepartments>(_onLoadDepartments);
    on<LoadEmployeeRoles>(_onLoadRoles);
    on<CreateEmployeeRequested>(_onCreate);
  }

  Future<void> _onLoadEmployees(
    LoadEmployees event,
    Emitter<EmployeesState> emit,
  ) async {
    final search = event.search ?? state.searchQuery;
    final limit = event.limit ?? state.limit;

    emit(state.copyWith(
      listStatus: RequestStatus.loading,
      listError: null,
      searchQuery: search,
    ));

    final result = await getEmployees(
      page: event.page,
      limit: limit,
      search: search.isEmpty ? null : search,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        listStatus: RequestStatus.failure,
        listError: failure.message,
      )),
      (pageData) => emit(state.copyWith(
        listStatus: RequestStatus.success,
        employees: pageData.items,
        page: pageData.page,
        limit: pageData.limit,
        total: pageData.total,
        totalPages: pageData.totalPages,
        hasNextPage: pageData.hasNextPage,
        hasPrevPage: pageData.hasPrevPage,
      )),
    );
  }

  Future<void> _onSearch(
    SearchEmployees event,
    Emitter<EmployeesState> emit,
  ) async {
    add(LoadEmployees(page: 1, search: event.query.trim()));
  }

  Future<void> _onUpdate(
    UpdateEmployeeRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(state.copyWith(
      updateStatus: FormStatus.submitting,
      updateError: null,
      updatingId: event.id,
    ));

    final result = await updateEmployee(id: event.id, data: event.data);

    result.fold(
      (failure) => emit(state.copyWith(
        updateStatus: FormStatus.failure,
        updateError: failure.message,
        clearUpdatingId: true,
      )),
      (updated) {
        // حدّث السطر محلياً دون إعادة تحميل الصفحة كاملة.
        final employees = state.employees
            .map((e) => e.id == updated.id ? updated : e)
            .toList();

        emit(state.copyWith(
          updateStatus: FormStatus.success,
          employees: employees,
          clearUpdatingId: true,
        ));
      },
    );
  }

  void _onResetFormStatus(
    ResetEmployeeFormStatus event,
    Emitter<EmployeesState> emit,
  ) {
    emit(state.copyWith(
      updateStatus: FormStatus.idle,
      updateError: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));
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