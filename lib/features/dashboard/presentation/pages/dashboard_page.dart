import 'package:flutter/material.dart';
import 'package:technical_team/shared/layouts/app_shell.dart';

import '../../../../shared/theme/app_colors.dart';
import '../widgets/dashboard_action_card.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.fromLTRB(40, 26, 40, 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'لوحة التحكم الرئيسية',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'نظرة شاملة على النظام الإلكتروني',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 34),
            _QuickActionsSection(),
            SizedBox(height: 32),
            _StatsSection(),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              const gap = 18.0;
              final itemWidth = (availableWidth - (gap * 4)) / 5;

              return Wrap(
                spacing: gap,
                runSpacing: 18,
                alignment: WrapAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  SizedBox(
                    width: itemWidth.clamp(180, 270),
                    child: const DashboardActionCard(
                      title: 'إنشاء مؤسسة',
                      icon: Icons.apartment_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth.clamp(180, 270),
                    child: const DashboardActionCard(
                      title: 'إنشاء قسم',
                      icon: Icons.folder_copy_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth.clamp(180, 270),
                    child: const DashboardActionCard(
                      title: 'إنشاء دور',
                      icon: Icons.shield_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth.clamp(180, 270),
                    child: const DashboardActionCard(
                      title: 'إنشاء حقل',
                      icon: Icons.storage_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth.clamp(180, 270),
                    child: const DashboardActionCard(
                      title: 'إنشاء معاملة',
                      icon: Icons.account_tree_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final stats = const [
      DashboardStatCard(
        title: 'عدد المؤسسات',
        value: '15',
        icon: Icons.apartment_outlined,
      ),
      DashboardStatCard(
        title: 'عدد الأقسام',
        value: '47',
        icon: Icons.folder_copy_outlined,
      ),
      DashboardStatCard(
        title: 'عدد الأدوار',
        value: '23',
        icon: Icons.shield_outlined,
        isSecondaryIcon: true,
      ),
      DashboardStatCard(
        title: 'عدد الحقول',
        value: '89',
        icon: Icons.storage_outlined,
      ),
      DashboardStatCard(
        title: 'عدد الملفات',
        value: '234',
        icon: Icons.description_outlined,
        isSecondaryIcon: true,
      ),
      DashboardStatCard(
        title: 'عدد القوالب',
        value: '12',
        icon: Icons.task_outlined,
      ),
      DashboardStatCard(
        title: 'عدد المعاملات',
        value: '8',
        icon: Icons.account_tree_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;
        final width = constraints.maxWidth;

        int columns = 4;
        if (width < 1250) columns = 3;
        if (width < 900) columns = 2;
        if (width < 560) columns = 1;

        final itemWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 22,
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.start,
          children: stats
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
