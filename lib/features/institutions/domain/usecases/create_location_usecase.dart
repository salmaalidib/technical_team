import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/location_option.dart';
import '../repositories/institution_repository.dart';

class CreateLocationUseCase {
  final InstitutionRepository repository;

  CreateLocationUseCase(this.repository);

  Future<Either<Failure, LocationOption>> call({
    required String name,
    required int typeLocationId,
    int? parentId,
  }) {
    return repository.createLocation(
      name: name,
      typeLocationId: typeLocationId,
      parentId: parentId,
    );
  }
}
