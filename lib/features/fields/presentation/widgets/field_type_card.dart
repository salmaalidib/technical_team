import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/field_type.dart';

/// Metadata for each FieldType: Arabic label, icon, description.
class FieldTypeMeta {
  final String label;
  final IconData icon;
  final String description;

  const FieldTypeMeta({
    required this.label,
    required this.icon,
    required this.description,
  });
}

const Map<FieldType, FieldTypeMeta> kFieldTypeMeta = {
  FieldType.textField: FieldTypeMeta(
    label: 'حقل نص',
    icon: Icons.text_fields_rounded,
    description: 'إدخال نص حر مع قيود الطول والنمط',
  ),
  FieldType.radioGroup: FieldTypeMeta(
    label: 'اختيار واحد',
    icon: Icons.radio_button_checked_rounded,
    description: 'اختيار خيار واحد من مجموعة',
  ),
  FieldType.textDropdown: FieldTypeMeta(
    label: 'قائمة منسدلة',
    icon: Icons.arrow_drop_down_circle_outlined,
    description: 'اختيار من قائمة منسدلة',
  ),
  FieldType.checkList: FieldTypeMeta(
    label: 'اختيار متعدد',
    icon: Icons.checklist_rounded,
    description: 'اختيار أكثر من خيار واحد',
  ),
  FieldType.datePicker: FieldTypeMeta(
    label: 'منتقي التاريخ',
    icon: Icons.calendar_month_rounded,
    description: 'اختيار تاريخ ضمن نطاق محدد',
  ),
  FieldType.filePicker: FieldTypeMeta(
    label: 'منتقي الملفات',
    icon: Icons.insert_drive_file_outlined,
    description: 'رفع ملف ضمن حدود وامتدادات محددة',
  ),
};

class FieldTypeCard extends StatelessWidget {
  final FieldType type;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const FieldTypeCard({
    super.key,
    required this.type,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kFieldTypeMeta[type]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meta.icon,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                _CountBadge(count: count, active: isSelected),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              meta.label,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool active;

  const _CountBadge({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
