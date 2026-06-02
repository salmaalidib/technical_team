import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_assignment.dart';
import '../repositories/role_repository.dart';

class CreateRoleUseCase {
  final RoleRepository repository;

  CreateRoleUseCase(this.repository);

  Future<Either<Failure, RoleAssignment>> call({
    required String name,
    required String code,
    required int organizationId,
    required int departmentId,
  }) {
    return repository.createRole(
      name: name,
      code: code,
      organizationId: organizationId,
      departmentId: departmentId,
    );
  }
}
