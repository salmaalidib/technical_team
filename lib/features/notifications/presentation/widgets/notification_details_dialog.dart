import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/notification_item.dart';

/// حوار يعرض تفاصيل إشعار واحد كاملةً — النص غير مقصوص هنا، بخلاف بطاقة
/// القائمة التي تقتصر على سطرين.
class NotificationDetailsDialog extends StatelessWidget {
  const NotificationDetailsDialog({super.key, required this.item});

  final NotificationItem item;

  static Future<void> show(BuildContext context, NotificationItem item) {
    return showDialog<void>(
      context: context,
      builder: (_) => NotificationDetailsDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: AppSpacing.allXl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _details(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.allSm,
            decoration: BoxDecoration(
              color: AppColors.lightPrimary,
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              _iconFor(item.type),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.createdAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _fullDate(item.createdAt!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  /// جدول التفاصيل — يُخفى كلياً إن لم يكن للإشعار أي حقل إضافي.
  Widget _details() {
    final rows = <(String, String)>[
      if (item.senderName != null && item.senderName!.isNotEmpty)
        ('المُرسِل', item.senderName!),
      if (item.transactionId != null)
        ('رقم المعاملة', '${item.transactionId}'),
      if (item.processInstanceId != null)
        ('رقم الإجراء', '${item.processInstanceId}'),
      if (item.type != null && item.type!.isNotEmpty)
        ('النوع', _typeLabel(item.type!)),
      (
        'الحالة',
        item.isRead
            ? (item.readAt != null
                ? 'مقروء — ${_fullDate(item.readAt!)}'
                : 'مقروء')
            : 'غير مقروء',
      ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.allLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// أيقونة حسب نوع الحدث القادم من الخادم (`transaction_rejected` ...).
IconData _iconFor(String? type) {
  if (type == null) return Icons.notifications_rounded;
  if (type.contains('reject')) return Icons.cancel_outlined;
  if (type.contains('approve')) return Icons.check_circle_outline_rounded;
  if (type.contains('assign')) return Icons.assignment_ind_outlined;
  if (type.contains('transaction')) return Icons.description_outlined;
  return Icons.notifications_rounded;
}

/// ترجمة مختصرة لأنواع الأحداث الشائعة، مع الرجوع إلى الرمز الخام لغير المعروف.
String _typeLabel(String type) {
  const labels = {
    'transaction_rejected': 'رفض معاملة',
    'transaction_approved': 'اعتماد معاملة',
    'transaction_created': 'معاملة جديدة',
    'transaction_assigned': 'إسناد معاملة',
    'transaction_completed': 'إنجاز معاملة',
  };
  return labels[type] ?? type;
}

String _two(int value) => value.toString().padLeft(2, '0');

/// تاريخ ووقت كاملان بصيغة `yyyy/MM/dd - HH:mm`.
String _fullDate(DateTime time) {
  return '${time.year}/${_two(time.month)}/${_two(time.day)}'
      ' - ${_two(time.hour)}:${_two(time.minute)}';
}
