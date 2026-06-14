import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_doc.dart';

/// Document-type operations backed by `/api/typeDoc`.
///
/// The backend supports list, create (name) and update (name / is_active).
/// There is no delete endpoint — deactivation via [updateTypeDoc] with
/// `isActive: false` is the soft-delete.
abstract class TypeDocRepository {
  Future<Either<Failure, List<TypeDoc>>> getTypeDocs();

  Future<Either<Failure, TypeDoc>> createTypeDoc({required String name});

  /// `PUT /api/typeDoc/{id}`. Sends only the provided fields (the backend
  /// requires at least one). Used for both rename and (de)activation.
  Future<Either<Failure, TypeDoc>> updateTypeDoc({
    required int id,
    String? name,
    bool? isActive,
  });
}
