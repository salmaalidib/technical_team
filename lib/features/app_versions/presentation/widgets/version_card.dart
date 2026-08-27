import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/app_version_row.dart';

/// بطاقة إصدار واحد. تُبرز `version_code` بوضوح لأنه الحقل الذي يقرّر فعلياً
/// ظهور التحديث، بينما `version_name` مجرّد نص للعرض.
class VersionCard extends StatelessWidget {
  final AppVersionRow version;

  /// أعلى رقم بناء مسجَّل على منصة هذا الإصدار — يُستخدم لتمييز «الإصدار
  /// المعروض حالياً» عن الإصدارات الأقدم.
  final int highestCodeOnPlatform;

  /// هل يشترك رقم البناء هذا مع صف آخر على المنصة نفسها؟ حالة تكسر الترتيب
  /// على الخادم وتستحق تحذيراً صريحاً.
  final bool hasDuplicateCode;

  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const VersionCard({
    super.key,
    required this.version,
    required this.highestCodeOnPlatform,
    required this.hasDuplicateCode,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  /// الإصدار الذي سيراه المستخدمون فعلاً: الأحدث *والمفعَّل*.
  bool get isServed =>
      version.isActive && version.versionCode == highestCodeOnPlatform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isServed ? AppColors.primary : AppColors.border,
          width: isServed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      version.versionName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    _Chip(
                      label: 'رقم البناء ${version.versionCode}',
                      color: AppColors.primary,
                      background: AppColors.lightPrimary,
                    ),
                    _Chip(
                      label: _platformLabel(version.platform),
                      color: AppColors.textSecondary,
                      background: AppColors.surfaceAlt,
                    ),
                    if (version.isActive)
                      const _Chip(
                        label: 'مُفعَّل',
                        color: AppColors.success,
                        background: AppColors.lightPrimary,
                      )
                    else
                      const _Chip(
                        label: 'غير مُفعَّل',
                        color: AppColors.textSecondary,
                        background: AppColors.surfaceAlt,
                      ),
                    if (isServed)
                      const _Chip(
                        label: 'المعروض للمستخدمين',
                        color: AppColors.white,
                        background: AppColors.primary,
                      ),
                    if (version.forceUpdateBelowVersionCode != null)
                      _Chip(
                        label:
                            'إجباري تحت ${version.forceUpdateBelowVersionCode}',
                        color: AppColors.warning,
                        background: AppColors.lightSecondary,
                      ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (hasDuplicateCode) ...[
            const SizedBox(height: 10),
            const _Warning(
              message: 'رقم البناء مكرَّر على هذه المنصة — الخادم يرتّب حسبه، '
                  'فقد لا يُعرض التحديث للمستخدمين على هذا الرقم.',
            ),
          ],
          if (version.isActive && (version.apkUrl ?? '').isEmpty) ...[
            const SizedBox(height: 10),
            const _Warning(
              message: 'الإصدار مُفعَّل بلا رابط تنزيل — سيعود الخادم إلى رابط '
                  'المتجر، وإن لم يكن مضبوطاً فلن يستطيع المستخدم التحديث.',
            ),
          ],
          if ((version.changelog ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              version.changelog!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if ((version.apkUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    version.apkUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                if (version.apkSize != null)
                  Text(
                    _formatSize(version.apkSize!),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),
          Row(
            children: [
              _Action(
                icon: Icons.edit_outlined,
                label: 'تعديل',
                color: AppColors.primary,
                onTap: busy ? null : onEdit,
              ),
              const SizedBox(width: 4),
              _Action(
                icon: version.isActive
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                label: version.isActive ? 'إيقاف' : 'تفعيل',
                color: version.isActive ? AppColors.warning : AppColors.success,
                onTap: busy ? null : onToggle,
              ),
              const Spacer(),
              _Action(
                icon: Icons.delete_outline_rounded,
                label: 'حذف',
                color: AppColors.error,
                onTap: busy ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatSize(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} م.ب';
    return '${(bytes / 1024).toStringAsFixed(0)} ك.ب';
  }

  static String _platformLabel(String platform) => switch (platform) {
        'windows' => 'ويندوز',
        'android' => 'أندرويد',
        'ios' => 'آيفون',
        _ => platform,
      };
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String message;
  const _Warning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 17, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.warningAlt,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
