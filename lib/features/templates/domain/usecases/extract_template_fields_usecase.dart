import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/extracted_field.dart';
import '../repositories/doc_template_repository.dart';

/// Reads the AcroForm field names out of a saved template's PDF — used in
/// step 2 so each PDF field can be mapped to a library field.
class ExtractTemplateFieldsUseCase {
  final DocTemplateRepository repository;

  ExtractTemplateFieldsUseCase(this.repository);

  Future<Either<Failure, List<ExtractedField>>> call(int id) =>
      repository.extractFields(id);
}
