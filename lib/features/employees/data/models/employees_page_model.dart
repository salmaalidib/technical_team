import '../../domain/entities/employees_page.dart';
import 'employee_model.dart';

class EmployeesPageModel extends EmployeesPage {
  const EmployeesPageModel({
    required super.items,
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
    required super.hasNextPage,
    required super.hasPrevPage,
  });

  /// يقرأ شكل `{ items: [...], pagination: { page, limit, total, totalPages,
  /// hasNextPage, hasPrevPage } }` الذي يعيده الـ backend.
  factory EmployeesPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination =
        (json['pagination'] as Map<String, dynamic>?) ?? const {};

    return EmployeesPageModel(
      items: items,
      page: (pagination['page'] ?? 1) as int,
      limit: (pagination['limit'] ?? items.length) as int,
      total: (pagination['total'] ?? items.length) as int,
      totalPages: (pagination['totalPages'] ?? 1) as int,
      hasNextPage: (pagination['hasNextPage'] ?? false) as bool,
      hasPrevPage: (pagination['hasPrevPage'] ?? false) as bool,
    );
  }
}
