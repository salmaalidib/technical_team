import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../app_update/presentation/bloc/app_update_bloc.dart';
import '../../../app_update/presentation/bloc/app_update_event.dart';
import '../../../app_update/presentation/bloc/app_update_state.dart';

/// صفحة "حول التطبيق" — تعرض رقم الإصدار الحالي وزر فحص تحديث يدوي.
/// (كانت DashboardPage — بقايا نسخ ولصق غير مستخدمة، انظر توثيق الميزة).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الإعدادات', style: AppTextStyles.heading),
                  const SizedBox(height: 24),
                  const _AboutCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حول التطبيق', style: AppTextStyles.heading.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data;
              final label = version == null
                  ? '...'
                  : 'الإصدار ${version.version} (${version.buildNumber})';
              return Text(label,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textSecondary));
            },
          ),
          const SizedBox(height: 20),
          BlocBuilder<AppUpdateBloc, AppUpdateState>(
            builder: (context, state) => _UpdateStatusArea(state: state),
          ),
        ],
      ),
    );
  }
}

class _UpdateStatusArea extends StatelessWidget {
  const _UpdateStatusArea({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      final p = state.downloadProgress;
      final label = state.phase == AppUpdatePhase.installing
          ? 'جارٍ التثبيت…'
          : (p >= 0 ? 'جارٍ التحميل ${(p * 100).round()}%' : 'جارٍ التحميل…');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: p >= 0 ? p : null, minHeight: 6),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.body),
        ],
      );
    }

    if (state.phase == AppUpdatePhase.checking) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('جارٍ التحقق من وجود تحديث…'),
        ],
      );
    }

    if (state.hasUpdate) {
      final info = state.info!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يتوفّر إصدار جديد: ${info.versionName}',
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(state.errorMessage!,
                style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: info.isDirectInstall
                ? () => context
                    .read<AppUpdateBloc>()
                    .add(const StartUpdateRequested())
                : null,
            child: Text(info.isDirectInstall ? 'تحديث الآن' : 'تواصل مع الدعم التقني'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            state.phase == AppUpdatePhase.upToDate
                ? 'التطبيق محدَّث لآخر إصدار.'
                : 'اضغط للتحقق من وجود تحديثات.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () =>
              context.read<AppUpdateBloc>().add(const CheckForUpdateRequested()),
          child: const Text('التحقق الآن'),
        ),
      ],
    );
  }
}
