import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/location_option.dart';
import '../repositories/institution_repository.dart';

class GetLocationsUseCase {
  final InstitutionRepository repository;

  GetLocationsUseCase(this.repository);

  Future<Either<Failure, List<LocationOption>>> call() {
    return repository.getLocations();
  }
}
