import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/file_repository.dart';

/// Creates a file definition when [id] is null, otherwise updates it.
class SaveFileUseCase {
  final FileRepository repository;

  SaveFileUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    int? id,
    required String name,
    required String fileType,
    required String classification,
  }) {
    if (id == null) {
      return repository.createFile(
        name: name,
        fileType: fileType,
        classification: classification,
      );
    }
    return repository.updateFile(
      id: id,
      name: name,
      fileType: fileType,
      classification: classification,
    );
  }
}
