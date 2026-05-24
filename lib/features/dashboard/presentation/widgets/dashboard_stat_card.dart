import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isSecondaryIcon;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isSecondaryIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            right: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSecondaryIcon
                    ? AppColors.inputBackground
                    : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color:
                    isSecondaryIcon ? AppColors.secondary : AppColors.primary,
                size: 25,
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
