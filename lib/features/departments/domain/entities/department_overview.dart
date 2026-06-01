import 'package:equatable/equatable.dart';

/// The user heading a department (top role assignment).
class DepartmentManager extends Equatable {
  final int id;
  final String name;
  final String? role;

  const DepartmentManager({required this.id, required this.name, this.role});

  @override
  List<Object?> get props => [id, name, role];
}

class DepartmentEmployee extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;

  const DepartmentEmployee({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, phone, role];
}

/// A sub-section = a child department.
class DepartmentSection extends Equatable {
  final int id;
  final String name;
  final bool isActive;

  const DepartmentSection({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, isActive];
}

/// Everything the department card needs, from `GET /api/department/:id/overview`.
class DepartmentOverview extends Equatable {
  final int id;
  final String name;
  final String? organizationName;
  final DepartmentManager? manager;
  final List<DepartmentEmployee> employees;
  final List<DepartmentSection> sections;
  final int employeesCount;
  final int sectionsCount;
  final int transactionsCount;

  const DepartmentOverview({
    required this.id,
    required this.name,
    this.organizationName,
    this.manager,
    this.employees = const [],
    this.sections = const [],
    this.employeesCount = 0,
    this.sectionsCount = 0,
    this.transactionsCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        organizationName,
        manager,
        employees,
        sections,
        employeesCount,
        sectionsCount,
        transactionsCount,
      ];
}
