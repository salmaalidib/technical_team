import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../institutions/domain/entities/institution.dart';
import '../entities/department.dart';
import '../entities/department_overview.dart';
import '../entities/leaf_department.dart';

abstract class DepartmentRepository {
  Future<Either<Failure, List<Department>>> getDepartments();

  /// Organizations used to populate the "create department" form
  /// (`organization_id` is required by the backend).
  Future<Either<Failure, List<Institution>>> getOrganizations();

  /// Leaf departments of an organization (full-path names), used to populate
  /// the department dropdown when assigning roles to that organization.
  Future<Either<Failure, List<LeafDepartment>>> getLeafDepartments(
    int organizationId,
  );

  Future<Either<Failure, DepartmentOverview>> getOverview(int id);

  Future<Either<Failure, Department>> createDepartment({
    required String name,
    required int organizationId,
    int? parentId,
  });

  Future<Either<Failure, Department>> toggleStatus(int id);
}
