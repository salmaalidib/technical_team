import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/layouts/page_header_row.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../bloc/audit_logs_bloc.dart';
import '../bloc/audit_logs_event.dart';
import '../bloc/audit_logs_state.dart';
import 'audit_log_status_badge.dart';

class AuditLogsHeader extends StatelessWidget {
  const AuditLogsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageHeaderRow(
      title: _HeaderTitle(),
      action: _RefreshButton(),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      // في RTL: start = اليمين. end كانت تدفع صفّ العنوان (الأضيق) بعيداً عن
      // اليمين بمقدار الفرق بينه وبين عرض النص الفرعي.
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.primary, size: 34),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'سجلات التدقيق',
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'سجل الأحداث الأمنية والإدارية في النظام — من فعل ماذا ومتى.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      buildWhen: (p, c) => p.status != c.status,
      builder: (context, state) {
        final isLoading = state.status == RequestStatus.loading;

        // نفس مقاسات وأسلوب زرّ الإجراء في شاشتي الأدوار وإصدارات التطبيقات.
        return SizedBox(
          width: 210,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () =>
                    context.read<AuditLogsBloc>().add(const RefreshAuditLogs()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: .55),
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.white,
                    ),
                  )
                else
                  const Icon(Icons.refresh_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  isLoading ? 'جارٍ التحديث…' : 'تحديث',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// شرائح فلترة سريعة بالحالة — الاستخدام الأشيع (عرض الفاشل/المحظور) دون فتح
/// لوحة الفلاتر الكاملة.
class AuditLogsStatusChips extends StatelessWidget {
  const AuditLogsStatusChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      buildWhen: (p, c) => p.filter.status != c.filter.status,
      builder: (context, state) {
        final selected = state.filter.status;

        return Wrap(
          textDirection: TextDirection.rtl,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatusChip(
              label: 'الكل',
              color: AppColors.primary,
              isSelected: selected == null,
              onTap: () =>
                  context.read<AuditLogsBloc>().add(const FilterByStatus(null)),
            ),
            for (final status in const [
              AuditLogStatus.success,
              AuditLogStatus.failure,
              AuditLogStatus.blocked,
            ])
              _StatusChip(
                label: status.label,
                color: auditStatusColor(status),
                isSelected: selected == status,
                onTap: () =>
                    context.read<AuditLogsBloc>().add(FilterByStatus(status)),
              ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allPill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: AppRadius.allPill,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
