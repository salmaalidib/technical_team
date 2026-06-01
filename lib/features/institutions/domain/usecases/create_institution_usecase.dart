import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/institution.dart';
import '../repositories/institution_repository.dart';

class CreateInstitutionUseCase {
  final InstitutionRepository repository;

  CreateInstitutionUseCase(this.repository);

  Future<Either<Failure, Institution>> call({
    required String name,
    int? parentId,
    int? locationId,
  }) {
    return repository.createInstitution(
      name: name,
      parentId: parentId,
      locationId: locationId,
    );
  }
}
