import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/form_config.dart';
import '../repositories/doc_template_repository.dart';

/// Create step 2: creates the fully-configured template in one call. [path] and
/// [url] are the values returned by [ExtractFieldsFromUploadUseCase]; [config]
/// is the `config_json` built from linking the extracted fields.
class CreateTemplateUseCase {
  final DocTemplateRepository repository;

  CreateTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call({
    required String name,
    required int typeDocId,
    required String path,
    required String url,
    required FormConfig config,
  }) {
    return repository.createTemplate(
      name: name,
      typeDocId: typeDocId,
      path: path,
      url: url,
      config: config,
    );
  }
}
