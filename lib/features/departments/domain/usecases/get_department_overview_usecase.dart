import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/department_overview.dart';
import '../repositories/department_repository.dart';

class GetDepartmentOverviewUseCase {
  final DepartmentRepository repository;

  GetDepartmentOverviewUseCase(this.repository);

  Future<Either<Failure, DepartmentOverview>> call(int id) {
    return repository.getOverview(id);
  }
}
