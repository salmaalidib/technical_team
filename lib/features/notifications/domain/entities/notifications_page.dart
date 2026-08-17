import 'package:equatable/equatable.dart';

import 'notification_item.dart';

/// صفحة إشعارات بترقيم **cursor** (لا أرقام صفحات): الخادم يعيد
/// `pagination.next_cursor` نمرّره كما هو لجلب الصفحة التالية.
class NotificationsPage extends Equatable {
  final List<NotificationItem> items;

  /// يُمرَّر كـ `?cursor=` لجلب ما بعد هذه الصفحة. `null` يعني لا مزيد.
  final String? nextCursor;
  final bool hasNext;
  final int limit;

  /// عدد غير المقروء لكامل حساب المستخدم — لا لهذه الصفحة وحدها. كل استجابات
  /// الوحدة تعيده محدَّثاً، فتبقى الشارة دقيقة دون طلب إضافي.
  final int unreadCount;

  const NotificationsPage({
    this.items = const [],
    this.nextCursor,
    this.hasNext = false,
    this.limit = 10,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [items, nextCursor, hasNext, limit, unreadCount];
}
