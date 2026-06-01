import '../../domain/entities/department_overview.dart';

class DepartmentOverviewModel extends DepartmentOverview {
  const DepartmentOverviewModel({
    required super.id,
    required super.name,
    super.organizationName,
    super.manager,
    super.employees,
    super.sections,
    super.employeesCount,
    super.sectionsCount,
    super.transactionsCount,
  });

  factory DepartmentOverviewModel.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'];
    final managerJson = json['manager'];

    final employees = (json['employees'] as List? ?? [])
        .whereType<Map>()
        .map((e) => DepartmentEmployee(
              id: e['id'] as int,
              name: (e['userName'] ?? '') as String,
              email: e['email'] as String?,
              phone: e['phone_number'] as String?,
              role: e['role'] as String?,
            ))
        .toList();

    final sections = (json['sections'] as List? ?? [])
        .whereType<Map>()
        .map((s) => DepartmentSection(
              id: s['id'] as int,
              name: (s['name'] ?? '') as String,
              isActive: (s['is_active'] ?? true) as bool,
            ))
        .toList();

    return DepartmentOverviewModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      organizationName:
          organization is Map ? organization['name'] as String? : null,
      manager: managerJson is Map
          ? DepartmentManager(
              id: managerJson['id'] as int,
              name: (managerJson['userName'] ?? '') as String,
              role: managerJson['role'] as String?,
            )
          : null,
      employees: employees,
      sections: sections,
      employeesCount: (json['employeesCount'] ?? employees.length) as int,
      sectionsCount: (json['sectionsCount'] ?? sections.length) as int,
      transactionsCount: (json['transactionsCount'] ?? 0) as int,
    );
  }
}
