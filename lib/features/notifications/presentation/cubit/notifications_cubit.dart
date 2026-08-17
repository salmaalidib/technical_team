import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/get_my_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_notifications_read_usecase.dart';
import 'notifications_state.dart';

/// حالة الإشعارات المشتركة بين شارة الجرس والقائمة المنسدلة.
///
/// يُسجَّل **singleton** لا factory: الشارة والقائمة يجب أن تقرآ نفس العدّاد،
/// ووصولُ إشعار عبر WebSocket يجب أن يحدّثهما معاً.
class NotificationsCubit extends Cubit<NotificationsState> {
  final GetMyNotificationsUseCase getMyNotifications;
  final MarkNotificationReadUseCase markRead;
  final MarkNotificationsReadUseCase markManyRead;

  NotificationsCubit({
    required this.getMyNotifications,
    required this.markRead,
    required this.markManyRead,
  }) : super(const NotificationsState());

  static const _pageSize = 10;

  /// تحميل أول صفحة (أو إعادة تحميلها). يُستدعى عند فتح القائمة وبعد وصول
  /// إشعار جديد عبر الـ WebSocket.
  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading, error: null));

    final result = await getMyNotifications(limit: _pageSize);

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: RequestStatus.success,
        items: page.items,
        unreadCount: page.unreadCount,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasNext: page.hasNext,
      )),
    );
  }

  /// جلب الصفحة التالية وإلحاقها بالقائمة الحالية.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (!state.hasNext || cursor == null || state.loadingMore) return;

    emit(state.copyWith(loadingMore: true, error: null));

    final result = await getMyNotifications(cursor: cursor, limit: _pageSize);

    result.fold(
      (failure) => emit(state.copyWith(
        loadingMore: false,
        error: failure.message,
      )),
      (page) => emit(state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.items],
        unreadCount: page.unreadCount,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasNext: page.hasNext,
      )),
    );
  }

  /// تعليم إشعار كمقروء بتحديث **متفائل**: نغيّر الحالة محلياً فوراً ثم نتراجع
  /// إن فشل الطلب، فلا ينتظر المستخدم الشبكة.
  Future<void> markAsRead(int id) async {
    final index = state.items.indexWhere((e) => e.id == id);
    if (index == -1 || state.items[index].isRead) return;

    final snapshot = state.items;
    final optimistic = [...snapshot];
    optimistic[index] = optimistic[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );

    emit(state.copyWith(
      items: optimistic,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      error: null,
    ));

    final result = await markRead(id);

    result.fold(
      // تراجَع إلى النسخة السابقة عند الفشل.
      (failure) => emit(state.copyWith(
        items: snapshot,
        unreadCount: state.unreadCount + 1,
        error: failure.message,
      )),
      // الخادم يعيد unread_count الحقيقي — اعتمده بدل تقديرنا المحلي.
      (data) => emit(state.copyWith(unreadCount: data.$2)),
    );
  }

  /// تعليم كل المعروض غير المقروء دفعةً واحدة (الخادم يقبل 100 كحد أقصى).
  Future<void> markAllAsRead() async {
    final unreadIds = state.items
        .where((e) => !e.isRead)
        .map((e) => e.id)
        .take(100)
        .toList();

    if (unreadIds.isEmpty) return;

    final snapshot = state.items;

    emit(state.copyWith(
      items: [
        for (final item in snapshot)
          item.isRead ? item : item.copyWith(isRead: true, readAt: DateTime.now()),
      ],
      unreadCount: 0,
      error: null,
    ));

    final result = await markManyRead(unreadIds);

    result.fold(
      (failure) => emit(state.copyWith(
        items: snapshot,
        unreadCount: snapshot.where((e) => !e.isRead).length,
        error: failure.message,
      )),
      (unread) => emit(state.copyWith(unreadCount: unread)),
    );
  }

  /// يُستدعى عند وصول إشعار عبر الـ WebSocket: نرفع العدّاد فوراً كي تتحرّك
  /// الشارة، ثم نعيد التحميل ليظهر الإشعار نفسه في القائمة.
  void onPushReceived() {
    emit(state.copyWith(unreadCount: state.unreadCount + 1));
    load();
  }

  /// تصفير كل شيء عند تسجيل الخروج — الـ cubit singleton يبقى حيًّا بعد الخروج،
  /// فلولا هذا لرأى المستخدمُ التالي إشعاراتِ من سبقه.
  void clear() => emit(const NotificationsState());
}
