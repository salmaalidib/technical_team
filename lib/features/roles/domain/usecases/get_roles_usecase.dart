import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_assignment.dart';
import '../repositories/role_repository.dart';

class GetRolesUseCase {
  final RoleRepository repository;

  GetRolesUseCase(this.repository);

  Future<Either<Failure, List<RoleAssignment>>> call() {
    return repository.getRoles();
  }
}
