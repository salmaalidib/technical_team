import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/audit_log_entry.dart';

/// ألوان الحالة — مشتركة بين الشارة وشرائح الفلترة السريعة كي يقرأ المستخدم
/// نفس اللون في الموضعين.
Color auditStatusColor(AuditLogStatus status) {
  switch (status) {
    case AuditLogStatus.success:
      return AppColors.success;
    case AuditLogStatus.failure:
      return AppColors.error;
    case AuditLogStatus.blocked:
      return AppColors.warning;
    case AuditLogStatus.unknown:
      return AppColors.neutral;
  }
}

IconData auditStatusIcon(AuditLogStatus status) {
  switch (status) {
    case AuditLogStatus.success:
      return Icons.check_circle_outline_rounded;
    case AuditLogStatus.failure:
      return Icons.error_outline_rounded;
    case AuditLogStatus.blocked:
      return Icons.block_rounded;
    case AuditLogStatus.unknown:
      return Icons.help_outline_rounded;
  }
}

class AuditLogStatusBadge extends StatelessWidget {
  final AuditLogStatus status;

  const AuditLogStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = auditStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: AppRadius.allPill,
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(auditStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
