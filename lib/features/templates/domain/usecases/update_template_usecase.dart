import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/doc_template.dart';
import '../entities/form_config.dart';
import '../repositories/doc_template_repository.dart';

/// Step 2 of authoring: set `config_json` on a template. The backend archives
/// the previous version and returns the new (latest) one.
class UpdateTemplateUseCase {
  final DocTemplateRepository repository;

  UpdateTemplateUseCase(this.repository);

  Future<Either<Failure, DocTemplate>> call({
    required int id,
    required FormConfig config,
  }) {
    return repository.updateConfig(id: id, config: config);
  }
}
