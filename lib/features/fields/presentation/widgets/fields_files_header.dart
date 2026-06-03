import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class FieldsFilesHeader extends StatelessWidget {
  final bool isFilesTab;
  final VoidCallback onCreate;

  const FieldsFilesHeader({
    super.key,
    required this.isFilesTab,
    required this.onCreate,
  });

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
                const Icon(Icons.storage_outlined,
                    color: AppColors.primary, size: 34),
                const SizedBox(width: 10),
                Text(
                  'إدارة الحقول والملفات',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تعريف الحقول الديناميكية والملفات القابلة لإعادة الاستخدام في المعاملات',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.add_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  isFilesTab ? 'إنشاء ملف جديد' : 'إنشاء حقل جديد',
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
