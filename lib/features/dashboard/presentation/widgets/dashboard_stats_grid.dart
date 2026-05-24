import 'package:flutter/material.dart';

import 'dashboard_stat_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        DashboardStatCard(
          title: 'المؤسسات',
          value: '24',
          icon: Icons.apartment_outlined,
        ),
        DashboardStatCard(
          title: 'الموظفين',
          value: '156',
          icon: Icons.group_outlined,
        ),
        DashboardStatCard(
          title: 'المعاملات',
          value: '89',
          icon: Icons.account_tree_outlined,
        ),
        DashboardStatCard(
          title: 'قوالب المستندات',
          value: '18',
          icon: Icons.description_outlined,
        ),
      ],
    );
  }
}