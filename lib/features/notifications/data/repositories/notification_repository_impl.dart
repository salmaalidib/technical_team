import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_item_model.dart';
import '../models/notifications_page_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remote;

  NotificationRepositoryImpl(this.remote);

  /// يفكّ غلاف `{ success, status_code, message, data }` ويُرجع محتوى data.
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, NotificationsPage>> getMyNotifications({
    String? cursor,
    int limit = 10,
    bool? unreadOnly,
  }) async {
    final result = await remote.getMyNotifications(
      cursor: cursor,
      limit: limit,
      unreadOnly: unreadOnly,
    );

    return result.fold(
      Left.new,
      (body) {
        final data = _payload(body);
        if (data is! Map<String, dynamic>) {
          return const Right(NotificationsPage());
        }
        return Right(NotificationsPageModel.fromJson(data));
      },
    );
  }

  @override
  Future<Either<Failure, (NotificationItem, int)>> markAsRead(int id) async {
    final result = await remote.markAsRead(id);

    return result.fold(
      Left.new,
      (body) {
        final data = _payload(body);
        if (data is! Map<String, dynamic>) {
          return const Left(ServerFailure('استجابة غير متوقعة من الخادم'));
        }

        // الاستجابة = عنصر الإشعار نفسه مضافاً إليه unread_count.
        final item = NotificationItemModel.fromJson(data);
        final unread = data['unread_count'];
        return Right((item, unread is num ? unread.toInt() : 0));
      },
    );
  }

  @override
  Future<Either<Failure, int>> markManyAsRead(List<int> ids) async {
    final result = await remote.markManyAsRead(ids);

    return result.fold(
      Left.new,
      (body) {
        final data = _payload(body);
        final unread =
            data is Map<String, dynamic> ? data['unread_count'] : null;
        return Right(unread is num ? unread.toInt() : 0);
      },
    );
  }
}
