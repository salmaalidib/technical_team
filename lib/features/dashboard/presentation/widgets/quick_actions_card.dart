import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _action(
            icon: Icons.add_business_outlined,
            title: 'إضافة مؤسسة',
          ),
          _action(
            icon: Icons.person_add_alt_outlined,
            title: 'إضافة موظف',
          ),
          _action(
            icon: Icons.note_add_outlined,
            title: 'إنشاء قالب',
          ),
          _action(
            icon: Icons.account_tree_outlined,
            title: 'معاملة جديدة',
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String title,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
