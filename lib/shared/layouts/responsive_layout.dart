import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget desktop;
  final Widget? tablet;
  final Widget? mobile;

  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    this.mobile,
  });

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1100;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 700;
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile ?? tablet ?? desktop;
  }
}