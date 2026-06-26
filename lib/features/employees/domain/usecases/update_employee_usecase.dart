import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../repositories/employee_repository.dart';

class UpdateEmployeeUseCase {
  final EmployeeRepository repository;

  UpdateEmployeeUseCase(this.repository);

  /// [data] حمولة جزئية (مفاتيح snake_case) — فقط الحقول المُراد تعديلها.
  Future<Either<Failure, Employee>> call({
    required int id,
    required Map<String, dynamic> data,
  }) {
    return repository.updateEmployee(id: id, data: data);
  }
}
