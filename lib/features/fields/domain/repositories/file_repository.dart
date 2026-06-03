import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/file_definition.dart';

abstract class FileRepository {
  Future<Either<Failure, List<FileDefinition>>> getFiles();

  Future<Either<Failure, Unit>> createFile({
    required String name,
    required String fileType,
    required String classification,
  });

  /// Updates a file definition (versioned server-side).
  Future<Either<Failure, Unit>> updateFile({
    required int id,
    required String name,
    required String fileType,
    required String classification,
  });
}
