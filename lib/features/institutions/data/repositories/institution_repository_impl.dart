import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/location_option.dart';
import '../../domain/repositories/institution_repository.dart';
import '../datasources/institution_remote_data_source.dart';
import '../models/institution_model.dart';
import '../models/location_model.dart';

class InstitutionRepositoryImpl implements InstitutionRepository {
  final InstitutionRemoteDataSource remote;

  InstitutionRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, List<Institution>>> getInstitutions() async {
    final result = await remote.getInstitutions();
    return result.fold<Either<Failure, List<Institution>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => InstitutionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة المؤسسات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<LocationOption>>> getLocations() async {
    final result = await remote.getLocations();
    return result.fold<Either<Failure, List<LocationOption>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) =>
                  LocationOptionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة المواقع.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Institution>> createInstitution({
    required String name,
    int? parentId,
    int? locationId,
  }) async {
    final result = await remote.createInstitution({
      'name': name.trim(),
      if (parentId != null) 'parent_id': parentId,
      if (locationId != null) 'location_id': locationId,
    });
    return result.fold<Either<Failure, Institution>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            InstitutionModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }
}
