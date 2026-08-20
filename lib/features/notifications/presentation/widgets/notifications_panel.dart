import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/notification_item.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../../../../shared/theme/app_dimens.dart';

/// القائمة المنسدلة التي تظهر عند الضغط على جرس الإشعارات.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  /// يعرضها كقائمة منسدلة أسفل [anchor] (زر الجرس).
  static Future<void> show(BuildContext context, RenderBox anchor) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return Future.value();

    final topLeft = anchor.localToGlobal(
      anchor.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );

    return showDialog<void>(
      context: context,
      barrierColor: AppColors.transparent,
      builder: (_) => Stack(
        children: [
          Positioned(
            top: topLeft.dy + 8,
            left: topLeft.dx,
            child: const Material(
              color: AppColors.transparent,
              child: NotificationsPanel(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final _scrollController = ScrollController();
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>()..load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// تحميل الصفحة التالية عند الاقتراب من نهاية القائمة (cursor pagination).
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider.value(
        value: _cubit,
        child: Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(unreadCount: state.unreadCount),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(child: _body(state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(NotificationsState state) {
    // أول تحميل فقط يستبدل المحتوى؛ إعادة التحميل بعد إشعار وارد تُبقي القائمة.
    if (state.status == RequestStatus.loading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (state.status == RequestStatus.failure && state.items.isEmpty) {
      return _Message(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        text: state.error ?? 'تعذّر جلب الإشعارات',
        onRetry: _cubit.load,
      );
    }

    if (state.items.isEmpty) {
      return const _Message(
        icon: Icons.notifications_off_outlined,
        color: AppColors.textSecondary,
        text: 'لا توجد إشعارات',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, i) {
        if (i >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final item = state.items[i];
        return _NotificationTile(
          item: item,
          onTap: () => _cubit.markAsRead(item.id),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      child: Row(
        children: [
          const Text(
            'الإشعارات',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unreadCount > 0)
            TextButton(
              onPressed: context.read<NotificationsCubit>().markAllAsRead,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'تعليم الكل كمقروء',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isRead ? null : onTap,
      child: Container(
        // غير المقروء بخلفية مميّزة كي يُميَّز بلمحة.
        color: item.isRead ? AppColors.surface : AppColors.lightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: item.isRead ? AppColors.transparent : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          item.isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (item.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt!),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وقت نسبي مختصر بالعربية ("قبل 5 د").
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
  if (diff.inDays < 30) return 'قبل ${diff.inDays} ي';

  final months = diff.inDays ~/ 30;
  return 'قبل $months شهر';
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.text,
    this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: color),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}
