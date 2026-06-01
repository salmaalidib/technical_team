import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

class CreateDepartmentUseCase {
  final DepartmentRepository repository;

  CreateDepartmentUseCase(this.repository);

  Future<Either<Failure, Department>> call({
    required String name,
    required int organizationId,
    int? parentId,
  }) {
    return repository.createDepartment(
      name: name,
      organizationId: organizationId,
      parentId: parentId,
    );
  }
}
