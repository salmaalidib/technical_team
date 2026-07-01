import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:technical_team/shared/theme/app_text_styles.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _illusController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    _illusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _decideStartDestination();
  }

  @override
  void dispose() {
    _illusController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _decideStartDestination() async {
    String? token;

    try {
      final storage = getIt<SecureStorageService>();

      final results = await Future.wait([
        storage.getToken(),
        Future<void>.delayed(const Duration(milliseconds: 2500)),
      ]);

      token = results.first as String?;
    } catch (_) {
      token = null;
    }

    final hasToken = token != null && token.isNotEmpty;

    if (!hasToken) {
      if (mounted) context.go('/login');
      return;
    }

    final activeOrg = getIt<ActiveOrganizationCubit>();

    try {
      await activeOrg.load();
    } catch (_) {}

    if (!mounted) return;

    context.go(
      activeOrg.hasActiveOrg ? '/dashboard' : '/select-organization',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary,
                AppColors.textPrimary,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  final angle = _bgController.value * 2 * pi;
                  return Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(cos(angle) * 180, sin(angle) * 180),
                      child: child!,
                    ),
                  );
                },
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.12),
                        AppColors.secondary.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  final angle = _bgController.value * 2 * pi + pi;
                  return Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(cos(angle) * 180, sin(angle) * 180),
                      child: child!,
                    ),
                  );
                },
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.textPrimary.withOpacity(0.08),
                        AppColors.textPrimary.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _illusController,
                      builder: (context, child) {
                        final value = CurvedAnimation(
                          parent: _illusController,
                          curve: Curves.easeInOut,
                        ).value;

                        final yOffset =
                            Tween<double>(begin: -10, end: 10).transform(value);
                        final scale = Tween<double>(begin: 0.97, end: 1.03)
                            .transform(value);

                        return Transform.translate(
                          offset: Offset(0, yOffset),
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: const Text(
                        'الفريق التقني',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeInDown(
                      delay: Duration(milliseconds: 150),
                      duration: Duration(milliseconds: 600),
                      child: Text(
                        'لوحة إدارة المعاملات والخدمات التقنية',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),
                    FadeIn(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                      child: const _CircularLoadingIndicator(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularLoadingIndicator extends StatefulWidget {
  const _CircularLoadingIndicator();

  @override
  State<_CircularLoadingIndicator> createState() =>
      _CircularLoadingIndicatorState();
}

class _CircularLoadingIndicatorState extends State<_CircularLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 3,
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary,
                    blurRadius: 8,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
