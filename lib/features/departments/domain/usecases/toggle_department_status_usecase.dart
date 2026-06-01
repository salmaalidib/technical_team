import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

class ToggleDepartmentStatusUseCase {
  final DepartmentRepository repository;

  ToggleDepartmentStatusUseCase(this.repository);

  Future<Either<Failure, Department>> call(int id) {
    return repository.toggleStatus(id);
  }
}
