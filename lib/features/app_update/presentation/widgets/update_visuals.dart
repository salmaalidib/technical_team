import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/app_update_info.dart';
import '../bloc/app_update_state.dart';

/// عناصر مشتركة بين شاشة التحديث الإجباري والحوار الاختياري، حتى تبقى
/// اللغة البصرية واحدة ولا يتفرّع التصميم بين المسارين.

/// يحوّل الحجم بالبايت إلى نص عربي مقروء («٣١٫٥ م.ب»).
/// يعيد null عند غياب الحجم أو كونه غير منطقي، فلا نعرض شارة فارغة.
String? formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return null;

  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;

  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} غ.ب';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} م.ب';
  if (bytes >= kb) return '${(bytes / kb).round()} ك.ب';
  return '$bytes بايت';
}

/// أيقونة التحديث داخل هالة دائرية متدرّجة — البؤرة البصرية للشاشة.
class UpdateBadge extends StatelessWidget {
  const UpdateBadge({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.system_update_rounded,
        size: size * .48,
        color: AppColors.white,
      ),
    );
  }
}

/// شريط ملخّص الإصدار: رقم الإصدار وحجم التنزيل جنباً إلى جنب.
///
/// حجم الملف كان يُقرأ من الخادم ولا يُعرض أبداً — وهو أول ما يريد المستخدم
/// معرفته قبل بدء تنزيل على اتصال بطيء.
class VersionSummary extends StatelessWidget {
  const VersionSummary({super.key, required this.info});

  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final size = formatFileSize(info.fileSize);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SummaryItem(
            icon: Icons.new_releases_rounded,
            label: 'الإصدار',
            value: info.versionName,
          ),
          if (size != null) ...[
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              color: AppColors.primary.withValues(alpha: .18),
            ),
            _SummaryItem(
              icon: Icons.sd_storage_rounded,
              label: 'حجم التنزيل',
              value: size,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            // الأرقام والنسخ تُقرأ يساراً-يميناً حتى داخل واجهة عربية.
            locale: const Locale('en'),
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

/// لوحة «ما الجديد» — تعرض سطور التغييرات كقائمة منقّطة بدل كتلة نص واحدة.
class ChangelogPanel extends StatelessWidget {
  const ChangelogPanel({
    super.key,
    required this.changelog,
    this.maxHeight = 168,
  });

  final String changelog;

  /// سقف الارتفاع؛ ما زاد عنه يُمرَّر داخلياً بدل أن يمدّ البطاقة بلا حدود.
  final double maxHeight;

  /// يقسّم النص إلى بنود، ويزيل أي رمز تنقيط موجود مسبقاً في المصدر حتى لا
  /// يتضاعف مع النقطة التي نرسمها.
  @visibleForTesting
  List<String> get linesForTest => _lines;

  List<String> get _lines => changelog
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*+]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ما الجديد',
                style: AppTextStyles.titleSmall.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 7),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                line,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// منطقة التقدّم أثناء التنزيل والتثبيت.
///
/// النسبة تُعرض رقماً بارزاً فوق الشريط، لأن شريطاً وحده لا يعطي إحساساً
/// بالتقدّم على ملفات كبيرة. عند تعذّر معرفة الحجم الكلي (-1) يصبح الشريط
/// غير محدّد بلا رقم مضلّل.
class UpdateProgressArea extends StatelessWidget {
  const UpdateProgressArea({super.key, required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final installing = state.phase == AppUpdatePhase.installing;
    final p = state.downloadProgress;
    final determinate = !installing && p >= 0;

    final label = installing
        ? 'جارٍ التثبيت…'
        : (p >= 0 ? 'جارٍ تنزيل التحديث' : 'جارٍ التنزيل…');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                value: installing ? null : (p >= 0 ? p : null),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (determinate)
              Text(
                '${(p * 100).round()}%',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
                textDirection: TextDirection.ltr,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: TweenAnimationBuilder<double>(
            // التقدّم يصل على دفعات من onReceiveProgress؛ الانتقال المتحرّك
            // يمنع القفزات المتقطّعة في الشريط.
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            tween: Tween(begin: 0, end: determinate ? p : 0),
            builder: (context, value, _) => LinearProgressIndicator(
              value: determinate ? value : null,
              minHeight: 8,
              backgroundColor: AppColors.lightPrimary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          installing
              ? 'سيُغلق التطبيق تلقائياً لإكمال التثبيت.'
              : 'يرجى إبقاء التطبيق مفتوحاً حتى انتهاء التنزيل.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// رسالة خطأ داخل لوحة حمراء خفيفة — أوضح من نص أحمر عائم.
class UpdateErrorNotice extends StatelessWidget {
  const UpdateErrorNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.errorDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ملاحظة محايدة — تُستخدم حين لا يوجد إجراء آلي متاح.
class UpdateNotice extends StatelessWidget {
  const UpdateNotice({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// الزر الرئيسي — بارتفاع ثابت وأيقونة تسبق النص.
class UpdatePrimaryButton extends StatelessWidget {
  const UpdatePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
