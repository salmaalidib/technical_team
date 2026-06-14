import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_doc.dart';
import '../repositories/type_doc_repository.dart';

class CreateTypeDocUseCase {
  final TypeDocRepository repository;

  CreateTypeDocUseCase(this.repository);

  Future<Either<Failure, TypeDoc>> call({required String name}) {
    return repository.createTypeDoc(name: name);
  }
}
