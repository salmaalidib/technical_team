import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class FieldsHeader extends StatelessWidget {
  const FieldsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded,
                color: AppColors.primary, size: 34),
            const SizedBox(width: 10),
            Text(
              'الحقول الديناميكية',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'عرّف وأدِر عناصر النماذج الستة القابلة لإعادة الاستخدام في المعاملات',
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
