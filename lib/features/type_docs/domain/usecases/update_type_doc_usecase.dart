import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/type_doc.dart';
import '../repositories/type_doc_repository.dart';

/// Serves both rename (`name`) and (de)activation (`isActive`) via the single
/// `PUT /api/typeDoc/{id}` endpoint.
class UpdateTypeDocUseCase {
  final TypeDocRepository repository;

  UpdateTypeDocUseCase(this.repository);

  Future<Either<Failure, TypeDoc>> call({
    required int id,
    String? name,
    bool? isActive,
  }) {
    return repository.updateTypeDoc(id: id, name: name, isActive: isActive);
  }
}
