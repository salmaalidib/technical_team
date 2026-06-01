import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/institution.dart';
import '../repositories/institution_repository.dart';

class GetInstitutionsUseCase {
  final InstitutionRepository repository;

  GetInstitutionsUseCase(this.repository);

  Future<Either<Failure, List<Institution>>> call() {
    return repository.getInstitutions();
  }
}
