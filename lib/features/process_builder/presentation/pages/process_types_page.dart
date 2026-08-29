import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../type_processes/domain/entities/type_process.dart';
import '../../../type_processes/presentation/bloc/type_processes_bloc.dart';
import '../../../type_processes/presentation/bloc/type_processes_event.dart';
import '../../../type_processes/presentation/bloc/type_processes_state.dart';
import '../../../type_processes/presentation/widgets/create_type_process_dialog.dart';
import '../widgets/process_animations.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Landing page for the technical team's transactions: manages process types
/// (create + activate/deactivate) and navigates into a type's processes list at
/// `/transactions/type/{id}`.
class ProcessTypesPage extends StatelessWidget {
  const ProcessTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TypeProcessesBloc>()..add(const LoadTypeProcesses()),
      child: BlocListener<TypeProcessesBloc, TypeProcessesState>(
        listenWhen: (p, c) => p.actionError != c.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            AppSnackBar.show(context,
                message: state.actionError!, isError: true);
          }
        },
        child: const _ProcessTypesView(),
      ),
    );
  }
}

class _ProcessTypesView extends StatelessWidget {
  const _ProcessTypesView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    return Container(
      color: AppColors.surfaceAlt,
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppEnterHeader(child: _Header()),
            SizedBox(height: 28),
            _Body(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  void _openCreate(BuildContext context) {
    final bloc = context.read<TypeProcessesBloc>();
    showDialog(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const CreateTypeProcessDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_tree_outlined,
                    color: AppColors.primary, size: 34),
                const SizedBox(width: 10),
                Text(
                  'المعاملات',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اختر نوع المعاملة لعرض معاملاته',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        SizedBox(
          width: 230,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _openCreate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.add_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  'إنشاء نوع معاملة',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TypeProcessesBloc, TypeProcessesState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.typeProcesses != c.typeProcesses ||
          p.togglingIds != c.togglingIds,
      builder: (context, state) {
        // كل فرع بمفتاح خاص كي يلتقط المبدّل الانتقال بين الحالات.
        late final Widget child;
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            child = const AppSkeleton.cards(key: ValueKey('loading'));
            break;
          case RequestStatus.failure:
            child = _ErrorState(
              key: const ValueKey('error'),
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () => context
                  .read<TypeProcessesBloc>()
                  .add(const LoadTypeProcesses()),
            );
            break;
          case RequestStatus.success:
            if (state.typeProcesses.isEmpty) {
              child = const Padding(
                key: ValueKey('empty'),
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'لا توجد أنواع معاملات لعرضها',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 15),
                  ),
                ),
              );
            } else {
              child = _TypesGrid(key: const ValueKey('grid'), state: state);
            }
            break;
        }
        return AppStateSwitcher(child: child);
      },
    );
  }
}

/// Responsive card grid: three columns on desktop, two on tablet, one on mobile.
class _TypesGrid extends StatelessWidget {
  final TypeProcessesState state;

  const _TypesGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
        final cardWidth = (width - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < state.typeProcesses.length; i++)
              SizedBox(
                width: cardWidth,
                child: AppEnter(
                  index: i,
                  child: _TypeTile(
                    key: ValueKey(state.typeProcesses[i].id),
                    type: state.typeProcesses[i],
                    toggling:
                        state.togglingIds.contains(state.typeProcesses[i].id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A tappable process-type tile: navigates to its processes list, with an
/// inline active/inactive toggle (the only field the backend lets us edit).
class _TypeTile extends StatelessWidget {
  final TypeProcess type;
  final bool toggling;

  const _TypeTile({super.key, required this.type, required this.toggling});

  @override
  Widget build(BuildContext context) {
    // البطاقة غير المفعّلة تُخفَّف كتلتها العلوية فقط، وحركة التخفيف نفسها
    // تتبع نفس مدّة تبديل المفتاح كي يبدو التغيير حركة واحدة.
    final dim = type.isActive ? 1.0 : 0.55;

    return AppHoverLift(
      borderRadius: AppRadius.allMd,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () =>
              context.push('/transactions/type/${type.id}', extra: type.name),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedOpacity(
                      duration: AppMotion.normal,
                      curve: AppMotion.curve,
                      opacity: dim,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.category_outlined,
                            color: AppColors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: AppMotion.normal,
                        curve: AppMotion.curve,
                        opacity: dim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (type.code.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                type.code,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _StatusToggle(type: type, toggling: toggling),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    _StatusChip(isActive: type.isActive),
                    const Spacer(),
                    const Text(
                      'عرض المعاملات',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Active / inactive toggle — `PUT /api/typeProcess/{id}` with `{ is_active }`.
class _StatusToggle extends StatelessWidget {
  final TypeProcess type;
  final bool toggling;

  const _StatusToggle({required this.type, required this.toggling});

  @override
  Widget build(BuildContext context) {
    // المؤشّر والمفتاح يتبادلان مكانهما بتلاشٍ بدل قفزة مفاجئة أثناء الحفظ.
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: toggling
          ? const SizedBox(
              key: ValueKey('toggling'),
              width: 46,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Switch.adaptive(
              key: const ValueKey('switch'),
              value: type.isActive,
              activeColor: AppColors.primary,
              onChanged: (value) => context.read<TypeProcessesBloc>().add(
                    ToggleTypeProcessStatus(id: type.id, isActive: value),
                  ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
            key: ValueKey(isActive),
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        AnimatedDefaultTextStyle(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          child: Text(isActive ? 'مفعّل' : 'غير مفعّل'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
