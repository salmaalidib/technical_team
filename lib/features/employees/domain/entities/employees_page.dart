import 'package:equatable/equatable.dart';

import 'employee.dart';

/// نتيجة مرقّمة من `GET /api/employees` — تطابق `{ items, pagination }`.
class EmployeesPage extends Equatable {
  final List<Employee> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const EmployeesPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  @override
  List<Object?> get props => [
        items,
        page,
        limit,
        total,
        totalPages,
        hasNextPage,
        hasPrevPage,
      ];
}
