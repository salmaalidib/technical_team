import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_item.dart';
import '../entities/notifications_page.dart';

abstract class NotificationRepository {
  /// صفحة من إشعارات المستخدم. [cursor] من `next_cursor` للصفحة السابقة،
  /// و[unreadOnly] يقصر النتيجة على غير المقروء.
  Future<Either<Failure, NotificationsPage>> getMyNotifications({
    String? cursor,
    int limit,
    bool? unreadOnly,
  });

  /// يعلّم إشعاراً واحداً كمقروء. يعيد الإشعار المحدَّث مع [unreadCount] الجديد.
  Future<Either<Failure, (NotificationItem, int)>> markAsRead(int id);

  /// يعلّم عدة إشعارات دفعةً واحدة (حد أقصى 100 معرّف). يعيد `unread_count`.
  Future<Either<Failure, int>> markManyAsRead(List<int> ids);
}
