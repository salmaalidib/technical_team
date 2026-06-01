import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../institutions/domain/entities/institution.dart';
import '../repositories/department_repository.dart';

/// Loads the organizations list for the create-department form's
/// (required) `organization_id` dropdown.
class GetDepartmentOrganizationsUseCase {
  final DepartmentRepository repository;

  GetDepartmentOrganizationsUseCase(this.repository);

  Future<Either<Failure, List<Institution>>> call() {
    return repository.getOrganizations();
  }
}
