import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class AppSidebar extends StatelessWidget {
  final double width;

  const AppSidebar({
    super.key,
    this.width = 270,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(
            color: AppColors.border,
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 115,
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 30, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'مديرية التربية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'ريف دمشق',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1.2,
            color: AppColors.border,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              children: const [
                _SidebarItem(
                  icon: Icons.home_outlined,
                  title: 'الرئيسية',
                  route: '/dashboard',
                ),
                _SidebarItem(
                  icon: Icons.apartment_outlined,
                  title: 'المؤسسات',
                  route: '/institutions',
                ),
                _SidebarItem(
                  icon: Icons.folder_outlined,
                  title: 'الأقسام والدوائر',
                  route: '/departments',
                ),
                _SidebarItem(
                  icon: Icons.shield_outlined,
                  title: 'الأدوار',
                  route: '/roles',
                ),
                _SidebarItem(
                  icon: Icons.storage_outlined,
                  title: 'الحقول والملفات',
                  route: '/fields',
                ),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  title: 'قوالب المستندات',
                  route: '/templates',
                ),
                _SidebarItem(
                  icon: Icons.account_tree_outlined,
                  title: 'المعاملات',
                  route: '/transactions',
                ),
                _SidebarItem(
                  icon: Icons.group_outlined,
                  title: 'الموظفين',
                  route: '/employees',
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  route: '/settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = location == route;
    return InkWell(
      onTap: () {
        final router = GoRouter.maybeOf(context);

        if (router != null) {
          router.go(route);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffF0EFE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
