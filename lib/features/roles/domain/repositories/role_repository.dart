import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/permission.dart';
import '../entities/role_assignment.dart';
import '../entities/role_by_department.dart';
import '../entities/role_permissions.dart';

/// Role-assignment operations backed by `/api/role`.
///
/// Organizations (for the create form) come from the institutions feature and
/// the department options come from the departments feature — this repository
/// only owns the role link itself.
abstract class RoleRepository {
  Future<Either<Failure, List<RoleAssignment>>> getRoles();

  Future<Either<Failure, RoleAssignment>> createRole({
    required String name,
    required String code,
    required int organizationId,
    required int departmentId,
  });

  Future<Either<Failure, RoleAssignment>> toggleStatus(int id);

  /// Roles linked to a single (leaf) department — `{ id, name, code }` rows.
  Future<Either<Failure, List<RoleByDepartment>>> getRolesByDepartment(
    int departmentId,
  );

  // ===== permissions =====
  //
  // Permissions attach to the (organization, department, role) triple rather
  // than to the role itself, so they live here alongside the role link.

  /// Every permission in the system — the option list for the role form.
  Future<Either<Failure, List<Permission>>> getPermissions();

  /// Permissions currently granted to the given triple.
  Future<Either<Failure, RolePermissions>> getRolePermissions({
    required int organizationId,
    required int departmentId,
    required int roleId,
  });

  /// Persists [permissionIds] for the triple.
  ///
  /// [replace] false → POST: adds to whatever is already granted (the backend
  /// rejects an empty list here). true → PUT: replaces the whole set, and an
  /// empty list clears every permission.
  Future<Either<Failure, RolePermissions>> saveRolePermissions({
    required int organizationId,
    required int departmentId,
    required int roleId,
    required List<int> permissionIds,
    bool replace = false,
  });
}
