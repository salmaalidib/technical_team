import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dynamic_field.dart';

abstract class FieldRepository {
  Future<Either<Failure, List<DynamicField>>> getFields();

  /// Creates a field. `listValues` is required by the backend only for the
  /// `choice` / `multiChoice` types. Returns [unit] on success — the caller
  /// reloads the list (the create response envelope is awkwardly nested).
  Future<Either<Failure, Unit>> createField({
    required String name,
    required String type,
    List<String>? listValues,
  });

  /// Updates a field (versioned server-side: deactivates the old row and
  /// creates a new active version).
  Future<Either<Failure, Unit>> updateField({
    required int id,
    required String name,
    required String type,
    List<String>? listValues,
  });
}
