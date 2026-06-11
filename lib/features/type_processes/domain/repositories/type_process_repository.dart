import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_process.dart';

/// Process-type operations backed by `/api/typeProcess`.
///
/// The backend supports only three operations: list, create (name) and
/// toggle the active flag.
abstract class TypeProcessRepository {
  Future<Either<Failure, List<TypeProcess>>> getTypeProcesses();

  Future<Either<Failure, TypeProcess>> createTypeProcess({
    required String name,
  });

  /// `PUT /api/typeProcess/{id}` with `{ is_active }`.
  Future<Either<Failure, TypeProcess>> updateStatus({
    required int id,
    required bool isActive,
  });
}
