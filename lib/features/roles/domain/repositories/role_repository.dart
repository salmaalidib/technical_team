import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/permission.dart';
import '../entities/role_assignment.dart';
import '../entities/role_by_department.dart';
import '../entities/role_catalog_item.dart';
import '../entities/role_permissions.dart';

/// Role-assignment operations backed by `/api/role`.
///
/// Organizations (for the create form) come from the institutions feature and
/// the department options come from the departments feature — this repository
/// only owns the role link itself.
abstract class RoleRepository {
  /// Role links of [organizationId] — the backend requires it and answers 400
  /// without it.
  Future<Either<Failure, List<RoleAssignment>>> getRoles(int organizationId);

  /// Every role defined in `roles`, independent of any organization — the
  /// option list for linking an existing role rather than defining a new one.
  Future<Either<Failure, List<RoleCatalogItem>>> getRoleCatalog();

  /// Links a role to an (organization, department) pair.
  ///
  /// Exactly one of the two modes must be supplied, matching the backend's
  /// validation: [roleId] reuses a role that already exists, while [name] +
  /// [code] define a new one. Sending both, or neither, is a 400.
  ///
  /// [parentId] is the link id of the role above this one in the hierarchy —
  /// null creates a root role, which the backend accepts.
  Future<Either<Failure, RoleAssignment>> createRole({
    int? roleId,
    String? name,
    String? code,
    required int organizationId,
    required int departmentId,
    int? parentId,
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

  /// The option list for the role form. [audience] picks the backend route:
  /// `all` → every permission, `employee` / `admin` → that audience plus the
  /// shared (`employee,citizen,admin`) rows.
  Future<Either<Failure, List<Permission>>> getPermissions({
    PermissionAudience audience = PermissionAudience.all,
  });

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
