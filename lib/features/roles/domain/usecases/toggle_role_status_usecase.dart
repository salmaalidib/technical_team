import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_assignment.dart';
import '../repositories/role_repository.dart';

class ToggleRoleStatusUseCase {
  final RoleRepository repository;

  ToggleRoleStatusUseCase(this.repository);

  Future<Either<Failure, RoleAssignment>> call(int id) {
    return repository.toggleStatus(id);
  }
}
