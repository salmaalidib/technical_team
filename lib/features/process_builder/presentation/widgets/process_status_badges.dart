import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import 'process_animations.dart';

/// Colored pill summarising a process's approval state. Works for both list
/// shapes: the admin tab passes `approvalStatus`, the review tab may also pass
/// the precomputed `isApproved` flag.
class ApprovalBadge extends StatelessWidget {
  final String? approvalStatus;
  final bool? isApproved;

  const ApprovalBadge({super.key, this.approvalStatus, this.isApproved});

  @override
  Widget build(BuildContext context) {
    final status = approvalStatus?.toUpperCase();
    final approved = isApproved ?? (status == 'APPROVED');

    late final String label;
    late final Color color;
    if (approved || status == 'APPROVED') {
      label = 'معتمدة';
      color = AppColors.success;
    } else if (status == 'REJECTED') {
      label = 'مرفوضة';
      color = AppColors.errorDark;
    } else {
      label = 'بانتظار الاعتماد';
      color = AppColors.warning;
    }

    return _Pill(label: label, color: color, icon: Icons.verified_outlined);
  }
}

/// Colored pill summarising whether the process is active.
class ActiveBadge extends StatelessWidget {
  final bool isActive;

  const ActiveBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: isActive ? 'مُفعّلة' : 'غير مُفعّلة',
      color: isActive ? AppColors.success : AppColors.neutral,
      icon: isActive ? Icons.toggle_on : Icons.toggle_off,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Pill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    // الشارة تُعيد بناء نفسها عند كل تفعيل/اعتماد، فتتحرّك ألوانها ونصّها
    // بدل أن تُستبدل فجأة.
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(icon, key: ValueKey(icon), size: 15, color: color),
          ),
          const SizedBox(width: 5),
          AnimatedDefaultTextStyle(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
