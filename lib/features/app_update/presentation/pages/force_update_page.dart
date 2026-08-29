import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../bloc/app_update_bloc.dart';
import '../bloc/app_update_event.dart';
import '../bloc/app_update_state.dart';
import '../widgets/update_visuals.dart';

/// شاشة التحديث الإجباري — تُعرض بدل splash عند force_update_enabled=true.
/// لا PopScope قابل للتجاوز: لا مسار آخر للمستخدم سوى التحديث.
///
/// التصميم يتبع لغة شاشات المصادقة: خلفية متدرّجة بلون الهوية مع دوائر
/// ذهبية متحركة، وبطاقة بيضاء مرفوعة تحمل المحتوى.
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage>
    with SingleTickerProviderStateMixin {
  /// يقود الدوائر المدارية في الخلفية — دورة بطيئة تدور بلا نهاية.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Stack(
            children: [
              Positioned.fill(
                child: _GradientBackdrop(controller: _controller),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xxxl,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: BlocBuilder<AppUpdateBloc, AppUpdateState>(
                          builder: (context, state) => _UpdateCard(state: state),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// خلفية متدرّجة بدوائر ذهبية تدور ببطء — نفس معجم شاشتَي الدخول والتحقق.
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _OrbitingCircle(
            controller: controller,
            size: 300,
            orbitRadius: 220,
            color: AppColors.secondary.withValues(alpha: .16),
          ),
          _OrbitingCircle(
            controller: controller,
            size: 240,
            orbitRadius: 220,
            startAngle: math.pi,
            color: AppColors.secondary.withValues(alpha: .10),
          ),
        ],
      ),
    );
  }
}

class _OrbitingCircle extends StatelessWidget {
  const _OrbitingCircle({
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final angle = startAngle + controller.value * 2 * math.pi;
        return Positioned(
          top: orbitRadius * math.sin(angle),
          right: orbitRadius * math.cos(angle),
          child: child!,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// البطاقة البيضاء المرفوعة التي تحمل كل محتوى الشاشة.
class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final info = state.info;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xxxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: UpdateBadge()),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'يتوفّر تحديث جديد',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'هذا التحديث إلزامي — يلزم تثبيته لمتابعة استخدام التطبيق.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (info != null) ...[
              const SizedBox(height: AppSpacing.xl),
              VersionSummary(info: info),
            ],
            if ((info?.changelog ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              ChangelogPanel(changelog: info!.changelog!),
            ],
            const SizedBox(height: AppSpacing.xxl),
            _ActionArea(state: state),
          ],
        ),
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      return UpdateProgressArea(state: state);
    }

    if (state.errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UpdateErrorNotice(message: state.errorMessage!),
          const SizedBox(height: AppSpacing.lg),
          UpdatePrimaryButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh_rounded,
            onPressed: () => context
                .read<AppUpdateBloc>()
                .add(const StartUpdateRequested()),
          ),
        ],
      );
    }

    // لا رابط تنزيل مباشر متاح حالياً على هذه المنصة — لا يوجد إجراء آلي.
    if (!(state.info?.isDirectInstall ?? false)) {
      return const UpdateNotice(
        icon: Icons.support_agent_rounded,
        message:
            'يرجى التواصل مع الدعم التقني للحصول على أحدث نسخة من التطبيق.',
      );
    }

    return UpdatePrimaryButton(
      label: 'تحديث الآن',
      icon: Icons.download_rounded,
      onPressed: () =>
          context.read<AppUpdateBloc>().add(const StartUpdateRequested()),
    );
  }
}
