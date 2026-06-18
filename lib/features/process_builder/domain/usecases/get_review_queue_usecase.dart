import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/review_queue_item.dart';
import '../repositories/process_builder_repository.dart';

class GetReviewQueueUseCase {
  final ProcessBuilderRepository repository;

  GetReviewQueueUseCase(this.repository);

  Future<Either<Failure, List<ReviewQueueItem>>> call({
    int page = 1,
    int limit = 100,
  }) {
    return repository.getReviewQueue(page: page, limit: limit);
  }
}
