import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../../roles/domain/entities/role_by_department.dart';
import '../../domain/entities/created_employee.dart';
import '../../domain/entities/employee.dart';

class EmployeesState extends Equatable {
  // ===== قائمة الموظفين =====
  final RequestStatus listStatus;
  final List<Employee> employees;
  final String? listError;

  // ترقيم
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  // بحث
  final String searchQuery;

  // ===== تعديل موظف =====
  final FormStatus updateStatus;
  final String? updateError;
  final int? updatingId;

  // ===== نموذج الإنشاء (موجود مسبقاً) =====
  final FormStatus formStatus;
  final String? formError;
  final CreatedEmployee? createdEmployee;

  // قوائم القسم/الدور (تُستخدم في نموذجي الإنشاء والتعديل)
  final List<LeafDepartment> departments;
  final List<RoleByDepartment> roles;
  final RequestStatus departmentsStatus;
  final RequestStatus rolesStatus;

  final String? actionError;

  const EmployeesState({
    this.listStatus = RequestStatus.initial,
    this.employees = const [],
    this.listError,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPrevPage = false,
    this.searchQuery = '',
    this.updateStatus = FormStatus.idle,
    this.updateError,
    this.updatingId,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.createdEmployee,
    this.departments = const [],
    this.roles = const [],
    this.departmentsStatus = RequestStatus.initial,
    this.rolesStatus = RequestStatus.initial,
    this.actionError,
  });

  EmployeesState copyWith({
    RequestStatus? listStatus,
    List<Employee>? employees,
    String? listError,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPrevPage,
    String? searchQuery,
    FormStatus? updateStatus,
    String? updateError,
    int? updatingId,
    bool clearUpdatingId = false,
    FormStatus? formStatus,
    String? formError,
    CreatedEmployee? createdEmployee,
    List<LeafDepartment>? departments,
    List<RoleByDepartment>? roles,
    RequestStatus? departmentsStatus,
    RequestStatus? rolesStatus,
    String? actionError,
  }) {
    return EmployeesState(
      listStatus: listStatus ?? this.listStatus,
      employees: employees ?? this.employees,
      listError: listError,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPrevPage: hasPrevPage ?? this.hasPrevPage,
      searchQuery: searchQuery ?? this.searchQuery,
      updateStatus: updateStatus ?? this.updateStatus,
      updateError: updateError,
      updatingId: clearUpdatingId ? null : (updatingId ?? this.updatingId),
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      createdEmployee: createdEmployee ?? this.createdEmployee,
      departments: departments ?? this.departments,
      roles: roles ?? this.roles,
      departmentsStatus: departmentsStatus ?? this.departmentsStatus,
      rolesStatus: rolesStatus ?? this.rolesStatus,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        listStatus,
        employees,
        listError,
        page,
        limit,
        total,
        totalPages,
        hasNextPage,
        hasPrevPage,
        searchQuery,
        updateStatus,
        updateError,
        updatingId,
        formStatus,
        formError,
        createdEmployee,
        departments,
        roles,
        departmentsStatus,
        rolesStatus,
        actionError,
      ];
}
