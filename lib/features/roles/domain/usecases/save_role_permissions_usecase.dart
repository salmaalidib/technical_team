import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_permissions.dart';
import '../repositories/role_repository.dart';

/// Attaches permissions to an (organization, department, role) triple.
///
/// One use case covers both verbs because the logic is identical — only the
/// HTTP method differs. [replace] false → POST (add), true → PUT (replace all).
class SaveRolePermissionsUseCase {
  final RoleRepository repository;

  SaveRolePermissionsUseCase(this.repository);

  Future<Either<Failure, RolePermissions>> call({
    required int organizationId,
    required int departmentId,
    required int roleId,
    required List<int> permissionIds,
    bool replace = false,
  }) {
    return repository.saveRolePermissions(
      organizationId: organizationId,
      departmentId: departmentId,
      roleId: roleId,
      permissionIds: permissionIds,
      replace: replace,
    );
  }
}
