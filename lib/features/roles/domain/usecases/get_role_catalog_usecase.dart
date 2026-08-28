import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/role_catalog_item.dart';
import '../repositories/role_repository.dart';

class GetRoleCatalogUseCase {
  final RoleRepository repository;

  GetRoleCatalogUseCase(this.repository);

  Future<Either<Failure, List<RoleCatalogItem>>> call() {
    return repository.getRoleCatalog();
  }
}
