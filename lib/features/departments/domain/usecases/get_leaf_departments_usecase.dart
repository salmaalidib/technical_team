import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/leaf_department.dart';
import '../repositories/department_repository.dart';

/// Returns the leaf departments of an organization, used to populate the
/// department dropdown when assigning a role to an organization.
class GetLeafDepartmentsUseCase {
  final DepartmentRepository repository;

  GetLeafDepartmentsUseCase(this.repository);

  Future<Either<Failure, List<LeafDepartment>>> call(int organizationId) {
    return repository.getLeafDepartments(organizationId);
  }
}
