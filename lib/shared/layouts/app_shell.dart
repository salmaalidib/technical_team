import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'responsive_layout.dart';
import 'sidebar.dart';
import 'topbar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ResponsiveLayout(
          desktop: Row(
            textDirection: TextDirection.rtl,
            children: [
              const AppSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const AppTopbar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
          tablet: Row(
            textDirection: TextDirection.rtl,
            children: [
              const AppSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const AppTopbar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
          mobile: Column(
            children: [
              const AppTopbar(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
