import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../bloc/app_update_bloc.dart';
import '../bloc/app_update_event.dart';
import '../bloc/app_update_state.dart';
import 'update_visuals.dart';

/// حوار تحديث قابل للتأجيل — يُعرض فقط عند soft_update_enabled=true
/// و force_update=false (انظر UpdateCheckResult).
Future<void> showOptionalUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.scrim,
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
      child: BlocBuilder<AppUpdateBloc, AppUpdateState>(
        builder: (context, state) {
          // أثناء التنزيل لا يُغلق الحوار بالنقر خارجه أو بزر الرجوع: إغلاقه
          // يخفي التقدّم بينما يستمر التنزيل في الخلفية بلا أي مؤشّر.
          return PopScope(
            canPop: !state.isBusy,
            child: Dialog(
              backgroundColor: AppColors.surface,
              insetPadding: const EdgeInsets.all(AppSpacing.lg),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(state: state),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                        ),
                        child: _Body(state: state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// رأس متدرّج يحمل الأيقونة والعنوان — يعطي الحوار حضوراً دون إثقاله.
class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تحديث جديد متاح',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يمكنك التحديث الآن أو تأجيله لوقت لاحق.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.whiteTranslucent,
                  ),
                ),
              ],
            ),
          ),
          // زر الإغلاق يختفي أثناء العمل حتى لا يبدو التنزيل قابلاً للإلغاء
          // من هنا بينما هو ماضٍ في الخلفية.
          if (!state.isBusy)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: AppColors.white,
              iconSize: 22,
              tooltip: 'إغلاق',
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final info = state.info;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (info != null) VersionSummary(info: info),
        if ((info?.changelog ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          ChangelogPanel(changelog: info!.changelog!, maxHeight: 140),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (state.isBusy)
          UpdateProgressArea(state: state)
        else ...[
          if (state.errorMessage != null) ...[
            UpdateErrorNotice(message: state.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          _Actions(
            primaryLabel:
                state.errorMessage != null ? 'إعادة المحاولة' : 'تحديث الآن',
            primaryIcon: state.errorMessage != null
                ? Icons.refresh_rounded
                : Icons.download_rounded,
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.primaryLabel, required this.primaryIcon});

  final String primaryLabel;
  final IconData primaryIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: UpdatePrimaryButton(
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: () => context
                .read<AppUpdateBloc>()
                .add(const StartUpdateRequested()),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: Text(
                'لاحقاً',
                style: AppTextStyles.titleSmall.copyWith(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
