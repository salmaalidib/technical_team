import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/active_org/active_organization_cubit.dart';
import '../theme/app_colors.dart';

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
        textDirection: TextDirection.ltr,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          if (!isCompact)
            const _UserInfo()
          else
            const SizedBox(
              width: 90,
              child: _UserInfo(compact: true),
            ),
          const SizedBox(width: 16),
          const _ActiveOrgBadge(),
          const Spacer(flex: 2),
          const SizedBox(width: 18),
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

/// Shows the user's active organization (chosen once after login). Read-only —
/// a quiet reminder of the context every form is scoped to.
class _ActiveOrgBadge extends StatelessWidget {
  const _ActiveOrgBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOrganizationCubit, ActiveOrgState>(
      builder: (context, state) {
        final name = state.activeOrg?.name;
        if (name == null || name.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lightPrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        Positioned(
          top: 8,
          right: 9,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xff7A2334),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
