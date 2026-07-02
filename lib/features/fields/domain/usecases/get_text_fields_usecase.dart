import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/text_field_entity.dart';
import '../repositories/fields_repository.dart';

class GetTextFieldsUseCase {
  final FieldsRepository repository;

  GetTextFieldsUseCase(this.repository);

  Future<Either<Failure, Paginated<TextFieldEntity>>> call({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return repository.getTextFields(page: page, limit: limit, search: search);
  }
}
