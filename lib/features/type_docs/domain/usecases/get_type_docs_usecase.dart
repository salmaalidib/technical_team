import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_doc.dart';
import '../repositories/type_doc_repository.dart';

class GetTypeDocsUseCase {
  final TypeDocRepository repository;

  GetTypeDocsUseCase(this.repository);

  Future<Either<Failure, List<TypeDoc>>> call() {
    return repository.getTypeDocs();
  }
}
