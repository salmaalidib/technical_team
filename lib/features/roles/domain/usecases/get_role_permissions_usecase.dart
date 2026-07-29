import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_permissions.dart';
import '../repositories/role_repository.dart';

/// Permissions currently granted to an (organization, department, role)
/// triple — used to pre-check the boxes when editing an existing role.
class GetRolePermissionsUseCase {
  final RoleRepository repository;

  GetRolePermissionsUseCase(this.repository);

  Future<Either<Failure, RolePermissions>> call({
    required int organizationId,
    required int departmentId,
    required int roleId,
  }) {
    return repository.getRolePermissions(
      organizationId: organizationId,
      departmentId: departmentId,
      roleId: roleId,
    );
  }
}
