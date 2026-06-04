import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_by_department.dart';
import '../repositories/role_repository.dart';

class GetRolesByDepartmentUseCase {
  final RoleRepository repository;

  GetRolesByDepartmentUseCase(this.repository);

  Future<Either<Failure, List<RoleByDepartment>>> call(int departmentId) {
    return repository.getRolesByDepartment(departmentId);
  }
}
