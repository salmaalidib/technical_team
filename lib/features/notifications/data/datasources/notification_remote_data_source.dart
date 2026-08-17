import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

class NotificationRemoteDataSource {
  final ApiService api;

  NotificationRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getMyNotifications({
    String? cursor,
    int limit = 10,
    bool? unreadOnly,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.myNotifications,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (unreadOnly == true) 'unread': true,
      },
    );
  }

  Future<Either<Failure, dynamic>> markAsRead(int id) {
    return api.makeRequest(
      method: ApiMethod.patch,
      endPoint: _endPoints.markNotificationRead(id),
    );
  }

  Future<Either<Failure, dynamic>> markManyAsRead(List<int> ids) {
    return api.makeRequest(
      method: ApiMethod.patch,
      endPoint: _endPoints.markNotificationsRead,
      body: {'notification_ids': ids},
    );
  }
}
