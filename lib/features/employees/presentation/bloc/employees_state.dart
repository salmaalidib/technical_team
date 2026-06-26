import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/entities/leaf_department.dart';
import '../../../roles/domain/entities/role_by_department.dart';
import '../../domain/entities/created_employee.dart';

class EmployeesState extends Equatable {
  final FormStatus formStatus;
  final String? formError;
  final CreatedEmployee? createdEmployee;

  final List<LeafDepartment> departments;
  final List<RoleByDepartment> roles;

  final RequestStatus departmentsStatus;
  final RequestStatus rolesStatus;

  final String? actionError;

  const EmployeesState({
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