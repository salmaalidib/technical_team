import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import 'department_stat_item.dart';

class DepartmentSectionCard extends StatelessWidget {
  final String sectionName;
  final String managerName;
  final String employeesCount;
  final String transactionsCount;

  const DepartmentSectionCard({
    super.key,
    required this.sectionName,
    required this.managerName,
    required this.employeesCount,
    required this.transactionsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xffFAF9F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.folder_outlined,
              color: AppColors.secondary, size: 26),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_left_rounded,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sectionName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'رئيس الشعبة: $managerName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          DepartmentStatItem(
            value: employeesCount,
            label: 'موظف',
            color: AppColors.secondary,
          ),
          const SizedBox(width: 22),
          DepartmentStatItem(
            value: transactionsCount,
            label: 'معاملة',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
