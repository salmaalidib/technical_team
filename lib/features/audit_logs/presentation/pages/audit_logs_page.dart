import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/audit_logs_bloc.dart';
import '../bloc/audit_logs_event.dart';
import '../bloc/audit_logs_state.dart';
import '../widgets/audit_logs_filter_bar.dart';
import '../widgets/audit_logs_header.dart';
import '../widgets/audit_logs_table.dart';

/// شاشة عرض سجلات التدقيق — بديل Swagger لـ `GET /api/auth/audit-logs`.
///
/// تتطلب صلاحية `VIEW_AUDIT_LOGS`؛ بدونها يردّ الخادم 403 وتُعرض رسالة
/// الصلاحية بدل قائمة فارغة غامضة.
class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuditLogsBloc>()..add(const LoadAuditLogs()),
      child: BlocListener<AuditLogsBloc, AuditLogsState>(
        // أخطاء «تحميل المزيد» تُعرض كـ snackbar فقط: الصفوف المحمّلة تبقى
        // على الشاشة بدل استبدالها بشاشة خطأ.
        listenWhen: (p, c) => p.loadMoreError != c.loadMoreError,
        listener: (context, state) {
          final error = state.loadMoreError;
          if (error != null) {
            AppSnackBar.show(context, message: error, isError: true);
          }
        },
        child: const _AuditLogsView(),
      ),
    );
  }
}

class _AuditLogsView extends StatelessWidget {
  const _AuditLogsView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return Container(
      color: AppColors.surfaceAlt,
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuditLogsHeader(),
            SizedBox(height: AppSpacing.xxl),
            AuditLogsFilterBar(),
            SizedBox(height: AppSpacing.lg),
            AuditLogsStatusChips(),
            SizedBox(height: AppSpacing.lg),
            _ResultsBody(),
          ],
        ),
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const AppSkeleton.table();

          case RequestStatus.failure:
            return _ErrorView(message: state.error ?? 'تعذّر جلب السجلات');

          case RequestStatus.success:
            if (state.items.isEmpty) {
              return _EmptyView(hasFilters: !state.filter.isEmpty);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultsSummary(count: state.items.length),
                const SizedBox(height: AppSpacing.md),
                AuditLogsTable(items: state.items),
                const SizedBox(height: AppSpacing.xl),
                const _LoadMoreBar(),
              ],
            );
        }
      },
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  final int count;

  const _ResultsSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'المعروض: $count سجل',
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// الترقيم بالـ cursor لا يعرف العدد الكلّي ولا يقفز إلى صفحة بعينها، لذا
/// «تحميل المزيد» بدل شريط أرقام صفحات.
class _LoadMoreBar extends StatelessWidget {
  const _LoadMoreBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      buildWhen: (p, c) =>
          p.hasNext != c.hasNext || p.isLoadingMore != c.isLoadingMore,
      builder: (context, state) {
        if (!state.hasNext) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'لا مزيد من السجلات',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Center(
          child: FilledButton.icon(
            onPressed: state.isLoadingMore
                ? null
                : () => context
                    .read<AuditLogsBloc>()
                    .add(const LoadMoreAuditLogs()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: .55),
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
            ),
            icon: state.isLoadingMore
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.expand_more_rounded, size: 20),
            label: Text(
              state.isLoadingMore ? 'جارٍ التحميل…' : 'تحميل المزيد',
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilters;

  const _EmptyView({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return _MessagePanel(
      icon: Icons.inbox_outlined,
      color: AppColors.textSecondary,
      title: hasFilters ? 'لا نتائج للفلاتر المحدّدة' : 'لا توجد سجلات تدقيق',
      message: hasFilters
          ? 'جرّب توسيع الفترة الزمنية أو مسح بعض الفلاتر.'
          : 'ستظهر الأحداث هنا فور تسجيلها في النظام.',
      action: hasFilters
          ? OutlinedButton.icon(
              onPressed: () => context
                  .read<AuditLogsBloc>()
                  .add(const ClearAuditLogFilter()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
              ),
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('مسح الفلاتر'),
            )
          : null,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return _MessagePanel(
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
      title: 'تعذّر عرض السجلات',
      message: message,
      action: OutlinedButton.icon(
        onPressed: () =>
            context.read<AuditLogsBloc>().add(const RefreshAuditLogs()),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        ),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('إعادة المحاولة'),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;

  const _MessagePanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
