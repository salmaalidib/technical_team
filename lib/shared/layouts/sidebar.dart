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
      barrierColor: Colors.black.withValues(alpha: .32),
      builder: (dialogContext) => _LogoutConfirmationDialog(
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
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
    final isCollapsed = widget.width <= 88;
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
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 12 : 18,
              12,
              isCollapsed ? 12 : 18,
              18,
            ),
            child: _LogoutButton(
              isCollapsed: isCollapsed,
              isLoading: _isLoggingOut,
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({
    required this.isCollapsed,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isCollapsed;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEmphasized = _isHovered || _isPressed;
    final foreground = isEmphasized ? AppColors.error : AppColors.textSecondary;
    final background = _isPressed
        ? AppColors.error.withValues(alpha: .12)
        : _isHovered
            ? AppColors.error.withValues(alpha: .08)
            : Colors.transparent;

    final button = MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.isLoading ? null : widget.onPressed,
        onTapDown:
            widget.isLoading ? null : (_) => setState(() => _isPressed = true),
        onTapUp:
            widget.isLoading ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            widget.isLoading ? null : () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? .985 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 16,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isEmphasized
                    ? AppColors.error.withValues(alpha: .12)
                    : AppColors.border.withValues(alpha: .7),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: .06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                else
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: _isHovered ? -3 : 0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    builder: (context, offset, child) => Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.logout_rounded,
                        key: ValueKey(isEmphasized),
                        size: 22,
                        color: foreground,
                      ),
                    ),
                  ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 13),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                      child: const Text(
                        'تسجيل الخروج',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return widget.isCollapsed
        ? Tooltip(message: 'تسجيل الخروج', child: button)
        : button;
  }
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .1),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 25,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'هل تريد تسجيل الخروج من النظام؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text('تسجيل الخروج'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
