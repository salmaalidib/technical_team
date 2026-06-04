import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class EmployeeStatusBadge extends StatelessWidget {
  final bool isActive;

  const EmployeeStatusBadge({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isActive ? AppColors.lightPrimary : const Color(0xffFDECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}