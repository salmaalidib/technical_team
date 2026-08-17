import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  /// يعيد الإشعار المحدَّث وعدد غير المقروء الجديد.
  Future<Either<Failure, (NotificationItem, int)>> call(int id) {
    return repository.markAsRead(id);
  }
}
