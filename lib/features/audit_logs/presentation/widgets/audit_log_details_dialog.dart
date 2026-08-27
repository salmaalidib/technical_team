import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/audit_log_entry.dart';
import 'audit_log_format.dart';
import 'audit_log_status_badge.dart';

/// تفاصيل سجل واحد — بما فيها حمولة `details` الحرّة التي لا تتّسع لها خانة
/// في الجدول.
class AuditLogDetailsDialog extends StatelessWidget {
  final AuditLogEntry entry;

  const AuditLogDetailsDialog({super.key, required this.entry});

  static Future<void> show(BuildContext context, AuditLogEntry entry) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.scrimLight,
      builder: (_) => AuditLogDetailsDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = entry.details.isEmpty
        ? null
        : const JsonEncoder.withIndent('  ').convert(entry.details);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 32,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(entry: entry),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Row(label: 'رقم السجل', value: '#${entry.id}'),
                      _Row(
                        label: 'الوقت',
                        value: auditFullDateTimeLabel(entry.createdAt),
                      ),
                      _Row(
                        label: 'المستخدم',
                        value: entry.user?.displayName ??
                            (entry.userId != null
                                ? 'مستخدم #${entry.userId}'
                                : 'النظام'),
                      ),
                      if (entry.user?.userName.isNotEmpty ?? false)
                        _Row(
                            label: 'اسم المستخدم', value: entry.user!.userName),
                      if (entry.user?.email.isNotEmpty ?? false)
                        _Row(label: 'البريد', value: entry.user!.email),
                      _Row(
                        label: 'نوع المورد',
                        value: auditResourceLabel(entry.resourceType),
                      ),
                      _Row(
                        label: 'معرّف المورد',
                        value: entry.resourceId ?? '—',
                      ),
                      _Row(label: 'عنوان IP', value: entry.ipAddress ?? '—'),
                      _Row(
                        label: 'وكيل المستخدم',
                        value: entry.userAgent ?? '—',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DetailsBlock(json: details),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.allSm,
                        ),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AuditLogEntry entry;

  const _Header({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = auditStatusColor(entry.status);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(auditStatusIcon(entry.status), color: color, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditActionLabel(entry.action),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                // الكود التقني تحت الاسم العربي: هو ما يُستخدم في الفلترة
                // وفي مراسلة الدعم.
                SelectableText(
                  entry.action,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AuditLogStatusBadge(status: entry.status),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsBlock extends StatelessWidget {
  final String? json;

  const _DetailsBlock({required this.json});

  @override
  Widget build(BuildContext context) {
    final payload = json;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            const Text(
              'التفاصيل',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (payload != null)
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (!context.mounted) return;
                  AppSnackBar.show(context, message: 'تم نسخ التفاصيل');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('نسخ', style: TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.allSm,
            border: Border.all(color: AppColors.border),
          ),
          child: payload == null
              ? const Text(
                  'لا توجد تفاصيل إضافية لهذا السجل.',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              // JSON يُقرأ يساراً-يميناً حتى داخل واجهة عربية.
              : SelectableText(
                  payload,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    fontFamily: 'monospace',
                    color: AppColors.textCharcoal,
                  ),
                ),
        ),
      ],
    );
  }
}
