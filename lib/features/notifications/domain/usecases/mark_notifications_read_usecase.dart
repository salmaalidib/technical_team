import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationsReadUseCase(this.repository);

  /// يعيد عدد غير المقروء بعد التحديث.
  Future<Either<Failure, int>> call(List<int> ids) {
    return repository.markManyAsRead(ids);
  }
}
