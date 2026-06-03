import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/file_definition.dart';
import '../repositories/file_repository.dart';

class GetFilesUseCase {
  final FileRepository repository;

  GetFilesUseCase(this.repository);

  Future<Either<Failure, List<FileDefinition>>> call() {
    return repository.getFiles();
  }
}
