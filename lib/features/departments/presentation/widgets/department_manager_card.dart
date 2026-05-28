import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class DepartmentManagerCard extends StatelessWidget {
  final String name;
  final String title;

  const DepartmentManagerCard({
    super.key,
    required this.name,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 1.8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 5,
            top: 10,
            child: Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          Positioned(
            right: 90,
            top: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
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
