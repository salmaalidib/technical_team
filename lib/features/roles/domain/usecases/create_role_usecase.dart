import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_assignment.dart';
import '../repositories/role_repository.dart';

class CreateRoleUseCase {
  final RoleRepository repository;

  CreateRoleUseCase(this.repository);

  /// Either [roleId] (link an existing role) or [name] + [code] (define a new
  /// one) — the backend rejects both together and neither at all.
  Future<Either<Failure, RoleAssignment>> call({
    int? roleId,
    String? name,
    String? code,
    required int organizationId,
    required int departmentId,
    int? parentId,
  }) {
    return repository.createRole(
      roleId: roleId,
      name: name,
      code: code,
      organizationId: organizationId,
      departmentId: departmentId,
      parentId: parentId,
    );
  }
}
