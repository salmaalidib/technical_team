import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employees_page.dart';
import '../repositories/employee_repository.dart';

class GetEmployeesUseCase {
  final EmployeeRepository repository;

  GetEmployeesUseCase(this.repository);

  Future<Either<Failure, EmployeesPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return repository.getEmployees(
      page: page,
      limit: limit,
      search: search,
    );
  }
}
