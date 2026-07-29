import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/permission.dart';
import '../repositories/role_repository.dart';

class GetPermissionsUseCase {
  final RoleRepository repository;

  GetPermissionsUseCase(this.repository);

  Future<Either<Failure, List<Permission>>> call() {
    return repository.getPermissions();
  }
}
