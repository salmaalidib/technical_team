import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_assignment.dart';
import '../entities/role_by_department.dart';

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
}
