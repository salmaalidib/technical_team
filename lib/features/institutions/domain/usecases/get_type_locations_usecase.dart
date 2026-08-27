import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_location_option.dart';
import '../repositories/institution_repository.dart';

class GetTypeLocationsUseCase {
  final InstitutionRepository repository;

  GetTypeLocationsUseCase(this.repository);

  Future<Either<Failure, List<TypeLocationOption>>> call() {
    return repository.getTypeLocations();
  }
}
