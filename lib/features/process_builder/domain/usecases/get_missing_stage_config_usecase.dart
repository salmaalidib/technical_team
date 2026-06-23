import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/missing_config_item.dart';
import '../repositories/process_builder_repository.dart';

/// `GET /api/process_definitions/admin/missing-stage-config` — processes that
/// still need stage configuration (opened in the wizard to be completed).
class GetMissingStageConfigUseCase {
  final ProcessBuilderRepository repository;

  GetMissingStageConfigUseCase(this.repository);

  Future<Either<Failure, List<MissingConfigItem>>> call({
    int page = 1,
    int limit = 100,
  }) =>
      repository.getMissingStageConfig(page: page, limit: limit);
}
