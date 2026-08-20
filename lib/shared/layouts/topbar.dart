import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_state.dart';
import '../../features/notifications/presentation/widgets/notifications_panel.dart';
import '../theme/app_colors.dart';
import '../../shared/theme/app_dimens.dart';

class AppTopbar extends StatelessWidget {
  const AppTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1050;

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300,
                minWidth: 150,
              ),
              child: const _SearchBox(),
            ),
          ),
          const SizedBox(width: 14),
          const _NotificationButton(),
          const Spacer(flex: 2),
          if (!isCompact)
            const _UserInfo()
          else
            const SizedBox(
              width: 90,
              child: _UserInfo(compact: true),
            ),
          const SizedBox(width: 14),
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person_outline,
              color: AppColors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final bool compact;

  const _UserInfo({
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 90 : 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أحمد محمود',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المسؤول التقني',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          hintText: 'بحث...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 22,
            color: AppColors.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 12,
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: getIt<NotificationsCubit>(),
      buildWhen: (p, c) => p.unreadCount != c.unreadCount,
      builder: (context, state) {
        final unread = state.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          // الشارة تُوضع بإحداثيات صريحة، فثبّت اتجاه الـ Stack كي لا تنقلب مع
          // اتجاه الشريط العلوي (RTL).
          textDirection: TextDirection.ltr,
          children: [
            InkWell(
              onTap: () {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) NotificationsPanel.show(context, box);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  unread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
            ),
            // الشارة تحمل العدد الحقيقي وتختفي عند الصفر (كانت نقطة ثابتة).
            if (unread > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentMaroon,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
