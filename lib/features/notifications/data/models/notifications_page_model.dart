import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page.dart';
import 'notification_item_model.dart';

/// يفكّ `data: { items, pagination: {...}, unread_count }`.
class NotificationsPageModel {
  const NotificationsPageModel._();

  static NotificationsPage fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <NotificationItem>[
      if (rawItems is List)
        for (final e in rawItems)
          if (e is Map<String, dynamic>) NotificationItemModel.fromJson(e),
    ];

    final pagination =
        json['pagination'] is Map<String, dynamic> ? json['pagination'] as Map<String, dynamic> : const <String, dynamic>{};

    return NotificationsPage(
      items: items,
      nextCursor: pagination['next_cursor']?.toString(),
      hasNext: pagination['has_next'] == true,
      limit: _int(pagination['limit']) ?? 10,
      unreadCount: _int(json['unread_count']) ?? 0,
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
