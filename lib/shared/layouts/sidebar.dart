import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/active_org/active_organization_cubit.dart';
import '../../core/di/injection.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';

class AppSidebar extends StatefulWidget {
  final double width;

  const AppSidebar({
    super.key,
    this.width = 270,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isLoggingOut = true);

    final result = await getIt<LogoutUseCase>()();
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() => _isLoggingOut = false);
        AppSnackBar.show(
          context,
          message: failure.message,
          isError: true,
        );
      },
      (_) async {
        await getIt<ActiveOrganizationCubit>().clear();
        if (!mounted) return;
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
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
                  icon: Icons.fact_check_outlined,
                  title: 'اعتماد المعاملات',
                  route: '/transactions/admin',
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
          const Divider(height: 1, thickness: 1.2, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: InkWell(
              onTap: _isLoggingOut ? null : _logout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (_isLoggingOut)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.error,
                        ),
                      )
                    else
                      const Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: AppColors.error,
                      ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'تسجيل الخروج',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
