import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

class GetDepartmentsUseCase {
  final DepartmentRepository repository;

  GetDepartmentsUseCase(this.repository);

  Future<Either<Failure, List<Department>>> call() {
    return repository.getDepartments();
  }
}
