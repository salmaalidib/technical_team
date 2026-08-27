import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_location_option.dart';
import '../repositories/institution_repository.dart';

class CreateTypeLocationUseCase {
  final InstitutionRepository repository;

  CreateTypeLocationUseCase(this.repository);

  Future<Either<Failure, TypeLocationOption>> call({required String name}) {
    return repository.createTypeLocation(name: name);
  }
}
