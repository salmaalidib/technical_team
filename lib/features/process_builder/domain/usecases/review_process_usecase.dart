import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/process_builder_repository.dart';

/// The approve/reject decision for `POST /api/process_definitions/{id}/review`.
enum ReviewDecision { approve, reject }

extension ReviewDecisionValue on ReviewDecision {
  String get value =>
      this == ReviewDecision.approve ? 'APPROVE' : 'REJECT';
}

/// `POST /api/process_definitions/{id}/review` — approve (publish) or reject.
class ReviewProcessUseCase {
  final ProcessBuilderRepository repository;

  ReviewProcessUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int id,
    required ReviewDecision decision,
  }) =>
      repository.reviewProcess(id: id, decision: decision.value);
}
