import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/type_process.dart';
import '../../domain/repositories/type_process_repository.dart';
import '../datasources/type_process_remote_data_source.dart';
import '../models/type_process_model.dart';

class TypeProcessRepositoryImpl implements TypeProcessRepository {
  final TypeProcessRemoteDataSource remote;

  TypeProcessRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, List<TypeProcess>>> getTypeProcesses() async {
    final result = await remote.getTypeProcesses();
    return result.fold<Either<Failure, List<TypeProcess>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => TypeProcessModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة أنواع العمليات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, TypeProcess>> createTypeProcess({
    required String name,
  }) async {
    final result = await remote.createTypeProcess({
      'name': name.trim(),
    });
    return result.fold<Either<Failure, TypeProcess>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            TypeProcessModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, TypeProcess>> updateStatus({
    required int id,
    required bool isActive,
  }) async {
    final result = await remote.updateTypeProcess(id, {
      'is_active': isActive,
    });
    return result.fold<Either<Failure, TypeProcess>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            TypeProcessModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر تحديث حالة نوع العملية.'));
        }
      },
    );
  }
}
