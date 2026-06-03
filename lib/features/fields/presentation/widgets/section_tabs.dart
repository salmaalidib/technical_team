import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Segmented control switching between the dynamic-fields and file-definitions
/// tabs, each showing a live count badge.
class SectionTabs extends StatelessWidget {
  final int activeIndex;
  final int fieldsCount;
  final int filesCount;
  final ValueChanged<int> onChanged;

  const SectionTabs({
    super.key,
    required this.activeIndex,
    required this.fieldsCount,
    required this.filesCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: _TabItem(
              icon: Icons.storage_outlined,
              label: 'الحقول الديناميكية',
              count: fieldsCount,
              selected: activeIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabItem(
              icon: Icons.description_outlined,
              label: 'تعريفات الملفات',
              count: filesCount,
              selected: activeIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.lightPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.primary : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
