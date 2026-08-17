import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notifications_page.dart';
import '../repositories/notification_repository.dart';

class GetMyNotificationsUseCase {
  final NotificationRepository repository;

  GetMyNotificationsUseCase(this.repository);

  Future<Either<Failure, NotificationsPage>> call({
    String? cursor,
    int limit = 10,
    bool? unreadOnly,
  }) {
    return repository.getMyNotifications(
      cursor: cursor,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }
}
