import 'package:equatable/equatable.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/entities/notification_item.dart';

class NotificationsState extends Equatable {
  final RequestStatus status;
  final List<NotificationItem> items;
  final String? error;

  /// عدد غير المقروء لكامل الحساب — مصدر الرقم في شارة الجرس.
  final int unreadCount;

  /// مؤشّر الصفحة التالية (cursor pagination). `null` = لا مزيد.
  final String? nextCursor;
  final bool hasNext;

  /// `true` أثناء جلب صفحة إضافية (لا يخفي القائمة الحالية).
  final bool loadingMore;

  const NotificationsState({
    this.status = RequestStatus.initial,
    this.items = const [],
    this.error,
    this.unreadCount = 0,
    this.nextCursor,
    this.hasNext = false,
    this.loadingMore = false,
  });

  NotificationsState copyWith({
    RequestStatus? status,
    List<NotificationItem>? items,
    String? error,
    int? unreadCount,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasNext,
    bool? loadingMore,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasNext: hasNext ?? this.hasNext,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        error,
        unreadCount,
        nextCursor,
        hasNext,
        loadingMore,
      ];
}
