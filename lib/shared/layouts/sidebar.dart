import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/active_org/active_organization_cubit.dart';
import '../../core/di/injection.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_snackbar.dart';

/// A single navigation entry. Kept as data so the rows can be built in a loop
/// and given a staggered entrance based on their index.
class _NavItem {
  final IconData icon;
  final String title;
  final String route;
  const _NavItem(this.icon, this.title, this.route);
}

const _navItems = <_NavItem>[
  _NavItem(Icons.home_outlined, 'الرئيسية', '/dashboard'),
  _NavItem(Icons.apartment_outlined, 'المؤسسات', '/institutions'),
  _NavItem(Icons.folder_outlined, 'الأقسام والدوائر', '/departments'),
  _NavItem(Icons.shield_outlined, 'الأدوار', '/roles'),
  _NavItem(Icons.group_outlined, 'الموظفين', '/employees'),
  _NavItem(Icons.account_tree_outlined, 'المعاملات', '/transactions'),
  _NavItem(Icons.fact_check_outlined, 'اعتماد المعاملات', '/transactions/admin'),
  _NavItem(Icons.description_outlined, 'قوالب المستندات', '/templates'),
  // _NavItem(Icons.settings_outlined, 'الإعدادات', '/settings'),
];

class AppSidebar extends StatefulWidget {
  final double width;

  const AppSidebar({
    super.key,
    this.width = 270,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    final curve =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerFade = curve;
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

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
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: const SizedBox(
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
              children: [
                for (var i = 0; i < _navItems.length; i++)
                  _SidebarItem(
                    icon: _navItems[i].icon,
                    title: _navItems[i].title,
                    route: _navItems[i].route,
                    // Stagger each row's entrance so the menu cascades in.
                    order: i,
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

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;

  /// Index of this row in the menu — drives its staggered entrance delay.
  final int order;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.order,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    // Slides in from the right (RTL) as it fades up.
    _slide = Tween<Offset>(
      begin: const Offset(0.18, 0),
      end: Offset.zero,
    ).animate(curved);

    // Stagger: each row starts a little after the one above it.
    Future.delayed(Duration(milliseconds: 60 + widget.order * 55), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = location == widget.route;
    final accent = selected ? AppColors.primary : AppColors.textPrimary;

    // Background: solid tint when selected, faint tint on hover, else clear.
    final bg = selected
        ? const Color(0xffF0EFE7)
        : _hovered
            ? const Color(0xffF0EFE7).withValues(alpha: .5)
            : Colors.transparent;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => GoRouter.maybeOf(context)?.go(widget.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 54,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // Sliding accent bar on the right edge — grows in when the
                  // row becomes the selected one.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    // easeOutBack overshoots below 0 while animating toward
                    // height 0, producing a negative (invalid) constraint.
                    // easeOut stays within the [0, 26] range.
                    curve: Curves.easeOut,
                    width: 4,
                    height: selected ? 26 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Icon nudges up in size when selected/hovered.
                  AnimatedScale(
                    scale: selected ? 1.12 : (_hovered ? 1.06 : 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(selected),
                        size: 22,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        // AnimatedDefaultTextStyle replaces the style outright,
                        // so the theme's Cairo fontFamily must be set here or
                        // the row falls back to the default font.
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: accent,
                      ),
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
