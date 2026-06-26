import 'package:equatable/equatable.dart';

abstract class EmployeesEvent extends Equatable {
  const EmployeesEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل صفحة من الموظفين (مع البحث الحالي إن وُجد).
class LoadEmployees extends EmployeesEvent {
  final int page;
  final int? limit;
  final String? search; // null = أبقِ البحث الحالي

  const LoadEmployees({this.page = 1, this.limit, this.search});

  @override
  List<Object?> get props => [page, limit, search];
}

/// تغيير نص البحث (يعيد التحميل من الصفحة 1).
class SearchEmployees extends EmployeesEvent {
  final String query;

  const SearchEmployees(this.query);

  @override
  List<Object?> get props => [query];
}

/// تعديل موظف. [data] حمولة جزئية بمفاتيح snake_case.
class UpdateEmployeeRequested extends EmployeesEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateEmployeeRequested({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

/// إعادة تهيئة حالة نموذج التعديل (بعد إغلاق الحوار).
class ResetEmployeeFormStatus extends EmployeesEvent {
  const ResetEmployeeFormStatus();
}

class LoadEmployeeDepartments extends EmployeesEvent {
  final int organizationId;

  const LoadEmployeeDepartments(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class LoadEmployeeRoles extends EmployeesEvent {
  final int departmentId;

  const LoadEmployeeRoles(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}

class CreateEmployeeRequested extends EmployeesEvent {
  final String firstName;
  final String lastName;
  final String fatherName;
  final String motherName;
  final String nationalId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String password;
  final String pin;
  final String confirmPin;
  final int organizationId;
  final int? departmentId;
  final int? roleId;
  final String publicKey;

  const CreateEmployeeRequested({
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.motherName,
    required this.nationalId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.pin,
    required this.confirmPin,
    required this.organizationId,
    this.departmentId,
    this.roleId,
    required this.publicKey,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        fatherName,
        motherName,
        nationalId,
        userName,
        email,
        phoneNumber,
        password,
        pin,
        confirmPin,
        organizationId,
        departmentId,
        roleId,
        publicKey,
      ];
}
