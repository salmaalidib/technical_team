import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class DepartmentEmployeeTile extends StatelessWidget {
  final String name;
  final String jobTitle;
  final String letter;

  const DepartmentEmployeeTile({
    super.key,
    required this.name,
    required this.jobTitle,
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.secondary,
          child: Text(
            letter,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              jobTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
