import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../bloc/app_update_bloc.dart';
import '../bloc/app_update_event.dart';
import '../bloc/app_update_state.dart';

/// شاشة التحديث الإجباري — تُعرض بدل splash عند force_update_enabled=true.
/// لا PopScope قابل للتجاوز: لا مسار آخر للمستخدم سوى التحديث.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: BlocBuilder<AppUpdateBloc, AppUpdateState>(
                    builder: (context, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.system_update_rounded,
                          size: 72,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'يتوفّر تحديث جديد',
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (state.info != null)
                          Text(
                            'الإصدار ${state.info!.versionName} متاح الآن — هذا التحديث إلزامي للمتابعة.',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        if ((state.info?.changelog ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.info!.changelog!,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _ActionArea(state: state),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      final p = state.downloadProgress;
      final label = state.phase == AppUpdatePhase.installing
          ? 'جارٍ التثبيت…'
          : (p >= 0 ? 'جارٍ التحميل ${(p * 100).round()}%' : 'جارٍ التحميل…');

      return Column(
        children: [
          LinearProgressIndicator(
            value: p >= 0 ? p : null,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.body),
        ],
      );
    }

    final info = state.info;
    final isDirect = info?.isDirectInstall ?? false;

    if (state.errorMessage != null) {
      return Column(
        children: [
          Text(
            state.errorMessage!,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'إعادة المحاولة',
            onPressed: () => context
                .read<AppUpdateBloc>()
                .add(const StartUpdateRequested()),
          ),
        ],
      );
    }

    if (!isDirect) {
      // لا رابط تنزيل مباشر متاح حالياً على هذه المنصة — لا يوجد إجراء آلي.
      return Text(
        'يرجى التواصل مع الدعم التقني للحصول على أحدث نسخة من التطبيق.',
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }

    return _PrimaryButton(
      label: 'تحديث الآن',
      onPressed: () =>
          context.read<AppUpdateBloc>().add(const StartUpdateRequested()),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: AppTextStyles.body.copyWith(color: Colors.white)),
      ),
    );
  }
}
