import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/institution.dart';
import '../entities/location_option.dart';
import '../entities/type_location_option.dart';

abstract class InstitutionRepository {
  Future<Either<Failure, List<Institution>>> getInstitutions();

  Future<Either<Failure, List<LocationOption>>> getLocations();

  Future<Either<Failure, List<TypeLocationOption>>> getTypeLocations();

  Future<Either<Failure, TypeLocationOption>> createTypeLocation({
    required String name,
  });

  Future<Either<Failure, LocationOption>> createLocation({
    required String name,
    required int typeLocationId,
    int? parentId,
  });

  Future<Either<Failure, Institution>> createInstitution({
    required String name,
    int? parentId,
    int? locationId,
  });
}
