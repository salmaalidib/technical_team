import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class DepartmentsHeader extends StatelessWidget {
  const DepartmentsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_outlined,
                    color: AppColors.primary, size: 34),
                const SizedBox(width: 10),
                Text(
                  'الهيكل التنظيمي للأقسام',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'عرض هرمي تفاعلي للدوائر والأقسام والشعب والموظفين',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        SizedBox(
          width: 210,
          height: 54,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.add_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  'إنشاء قسم جديد',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
