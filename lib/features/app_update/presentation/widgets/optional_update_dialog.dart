import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../bloc/app_update_bloc.dart';
import '../bloc/app_update_event.dart';
import '../bloc/app_update_state.dart';

/// حوار تحديث قابل للتأجيل — يُعرض فقط عند soft_update_enabled=true
/// و force_update=false (انظر UpdateCheckResult).
Future<void> showOptionalUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<AppUpdateBloc>(),
      child: const _OptionalUpdateDialog(),
    ),
  );
}

class _OptionalUpdateDialog extends StatelessWidget {
  const _OptionalUpdateDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<AppUpdateBloc, AppUpdateState>(
            listener: (context, state) {
              // بعد نجاح إطلاق المثبِّت يخرج التطبيق من تلقاء نفسه (exit(0))
              // — لا حاجة لإغلاق الحوار يدوياً في الحالة السعيدة.
            },
            builder: (context, state) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تحديث جديد متاح',
                      style: AppTextStyles.heading.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (state.info != null)
                      Text(
                        'الإصدار ${state.info!.versionName}',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    if ((state.info?.changelog ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.info!.changelog!,
                        style: AppTextStyles.body,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (state.isBusy)
                      _ProgressArea(state: state)
                    else if (state.errorMessage != null)
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.body.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('لاحقاً'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => context
                                  .read<AppUpdateBloc>()
                                  .add(const StartUpdateRequested()),
                              child: const Text('تحديث الآن'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressArea extends StatelessWidget {
  const _ProgressArea({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final p = state.downloadProgress;
    final label = state.phase == AppUpdatePhase.installing
        ? 'جارٍ التثبيت…'
        : (p >= 0 ? 'جارٍ التحميل ${(p * 100).round()}%' : 'جارٍ التحميل…');

    return Column(
      children: [
        LinearProgressIndicator(value: p >= 0 ? p : null, minHeight: 6),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.body),
      ],
    );
  }
}
