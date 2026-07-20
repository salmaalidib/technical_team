import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:technical_team/core/di/injection.dart';

import '../bloc/login/login_bloc.dart';
import '../widgets/login_form.dart';

const _forest = Color(0xFF054239);
const _forestDark = Color(0xFF002623);
const _gold = Color(0xFFB9A779);
const _goldLight = Color(0xFFEDEBE0);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _circlesController;

  @override
  void initState() {
    super.initState();
    _circlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _circlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                _MovingCircle(
                  controller: _circlesController,
                  size: 320,
                  orbitRadius: 240,
                  color: _gold.withValues(alpha: .12),
                ),
                _MovingCircle(
                  controller: _circlesController,
                  size: 340,
                  orbitRadius: 240,
                  startAngle: math.pi,
                  color: _forest.withValues(alpha: .08),
                ),
                if (isWide) _wideLayout() else _compactLayout(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const LoginForm(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: FadeInRight(
            duration: const Duration(milliseconds: 600),
            child: _LoginIllustration(controller: _circlesController),
          ),
        ),
      ],
    );
  }

  Widget _compactLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: const _CompactBranding(),
              ),
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_forest, _forestDark],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _MovingCircle(
            controller: controller,
            size: 280,
            orbitRadius: 210,
            color: _gold.withValues(alpha: .18),
          ),
          _MovingCircle(
            controller: controller,
            size: 260,
            orbitRadius: 210,
            startAngle: math.pi,
            color: _goldLight.withValues(alpha: .14),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: SizedBox(
              height: math.max(500, MediaQuery.sizeOf(context).height - 80),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FloatingLogo(size: 140, distance: 8, scales: true),
                    SizedBox(height: 36),
                    Text(
                      'مديرية التربية في ريف دمشق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'الفريق التقني الخاص بمديرية التربية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xD9EDEBE0),
                      ),
                    ),
                    SizedBox(height: 48),
                    _SecurityBadge(),
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

class _CompactBranding extends StatelessWidget {
  const _CompactBranding();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FloatingLogo(size: 85, distance: 6),
        SizedBox(height: 18),
        Text(
          'مديرية التربية في ريف دمشق',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _forest,
          ),
        ),
        Text(
          'الفريق التقني الخاص بمديرية التربية',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF757575),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: 80,
          child: Divider(height: 1.5, thickness: 1.5, color: Color(0xFFEEEEEE)),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}

class _FloatingLogo extends StatefulWidget {
  const _FloatingLogo({
    required this.size,
    required this.distance,
    this.scales = false,
  });

  final double size;
  final double distance;
  final bool scales;

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final eased = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.distance + (widget.distance * 2 * eased)),
          child: Transform.scale(
            scale: widget.scales ? .98 + (.04 * eased) : 1,
            child: child,
          ),
        );
      },
      child: SvgPicture.asset(
        'assets/vectors/syria-logo.svg',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 18, color: _gold),
          SizedBox(width: 10),
          Text(
            'نظام آمن ومحمي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovingCircle extends StatelessWidget {
  const _MovingCircle({
    required this.controller,
    required this.size,
    required this.orbitRadius,
    required this.color,
    this.startAngle = 0,
  });

  final AnimationController controller;
  final double size;
  final double orbitRadius;
  final Color color;
  final double startAngle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final angle = startAngle + controller.value * math.pi * 2;
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * orbitRadius,
                math.sin(angle) * orbitRadius,
              ),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
