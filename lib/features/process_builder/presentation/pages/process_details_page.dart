import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../domain/entities/process_details.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import '../widgets/process_animations.dart';
import '../widgets/process_status_badges.dart';
import '../widgets/stage_config_view.dart';

/// Full details of one process (`GET /api/process_definitions/{id}/details`):
/// a header summary, the setup verdict, then the stages as a vertical timeline.
///
/// The page is intentionally free of technical identifiers — every entity is
/// shown by its name, never by its database id.
class ProcessDetailsPage extends StatelessWidget {
  final int id;

  const ProcessDetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProcessListBloc>()..add(LoadProcessDetails(id)),
      child: _DetailsScaffold(id: id),
    );
  }
}

class _DetailsScaffold extends StatelessWidget {
  final int id;

  const _DetailsScaffold({required this.id});

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return Container(
      color: AppColors.surfaceAlt,
      padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEnterHeader(
            child: _BackBar(
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go('/transactions'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BlocBuilder<ProcessListBloc, ProcessListState>(
              buildWhen: (p, c) =>
                  p.detailsStatus != c.detailsStatus || p.details != c.details,
              builder: (context, state) {
                // كل فرع بمفتاح خاص كي يلتقط المبدّل الانتقال بين الحالات.
                late final Widget child;
                switch (state.detailsStatus) {
                  case RequestStatus.initial:
                  case RequestStatus.loading:
                    child = const AppSkeleton.list(
                        key: ValueKey('loading'), itemCount: 6);
                    break;
                  case RequestStatus.failure:
                    child = _ErrorState(
                      key: const ValueKey('error'),
                      message: state.detailsError ?? 'حدث خطأ غير متوقع',
                      onRetry: () => context
                          .read<ProcessListBloc>()
                          .add(LoadProcessDetails(id)),
                    );
                    break;
                  case RequestStatus.success:
                    final d = state.details;
                    child = d == null
                        ? const _EmptyState(key: ValueKey('empty'))
                        : _DetailsBody(key: const ValueKey('body'), details: d);
                    break;
                }
                return AppStateSwitcher(child: child);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  final VoidCallback onBack;
  const _BackBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'تفاصيل المعاملة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final ProcessDetails details;

  const _DetailsBody({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final stages = details.stages;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AppEnter(index: 0, child: _ProcessHeaderCard(info: details.process)),
          const SizedBox(height: AppSpacing.lg),
          AppEnter(
            index: 1,
            child: _ValidationCard(validation: details.validation),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppEnter(
            index: 2,
            child: _SectionHeader(
              icon: Icons.account_tree_rounded,
              title: 'مراحل المعاملة',
              count: stages.length,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (stages.isEmpty)
            const AppEnter(
              index: 3,
              child: _InlineNotice(
                icon: Icons.layers_clear_rounded,
                text: 'لم تُضَف أي مرحلة إلى هذه المعاملة بعد',
              ),
            )
          else
            // المراحل تنزل تباعاً فيُقرأ الخطّ الزمني من أعلى إلى أسفل.
            for (var i = 0; i < stages.length; i++)
              AppEnter(
                index: i + 3,
                child: _TimelineRow(
                  order: i + 1,
                  isLast: i == stages.length - 1,
                  child: _StageCard(stage: stages[i]),
                ),
              ),
        ],
      ),
    );
  }
}

/// A numbered node joined to the next one by a vertical connector, so the
/// stages read as an ordered flow rather than a stack of loose cards.
class _TimelineRow extends StatelessWidget {
  final int order;
  final bool isLast;
  final Widget child;

  const _TimelineRow({
    required this.order,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$order',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: SizedBox(
                    width: 2,
                    child: ColoredBox(color: AppColors.border),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessHeaderCard extends StatelessWidget {
  final ProcessInfo info;

  const _ProcessHeaderCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadius.allLg,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.whiteTranslucent.withOpacity(0.15),
                  borderRadius: AppRadius.allMd,
                ),
                child: const Icon(Icons.description_rounded,
                    color: AppColors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ApprovalBadge(
                approvalStatus: info.approvalStatus,
                isApproved: info.isApproved,
              ),
              ActiveBadge(isActive: info.isActive),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DateRow(startDate: info.startDate, endDate: info.endDate),
        ],
      ),
    );
  }
}

/// Emphasised start/end dates for the process, laid out on the hero card.
class _DateRow extends StatelessWidget {
  final String? startDate;
  final String? endDate;

  const _DateRow({this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _DateChip(
          icon: Icons.event_available_rounded,
          label: 'تاريخ البدء',
          value: _fmt(startDate),
        ),
        _DateChip(
          icon: Icons.event_busy_rounded,
          label: 'تاريخ الانتهاء',
          value: _fmt(endDate),
        ),
      ],
    );
  }

  static String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return 'غير محدد';
    // Keep just the date part if an ISO timestamp comes back.
    final t = raw.indexOf('T');
    return t > 0 ? raw.substring(0, t) : raw;
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DateChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.whiteTranslucent.withOpacity(0.13),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.whiteTranslucent.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.white.withOpacity(0.75),
                  )),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  final ProcessValidation validation;

  const _ValidationCard({required this.validation});

  @override
  Widget build(BuildContext context) {
    final valid = validation.isValid;
    final color = valid ? AppColors.success : AppColors.errorDark;

    return _Card(
      borderColor: color.withOpacity(0.35),
      background: color.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  valid ? Icons.verified_rounded : Icons.report_problem_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  valid ? 'إعداد المعاملة مكتمل' : 'إعداد المعاملة غير مكتمل',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (!valid && validation.errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final err in validation.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle,
                          size: 5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        err,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final ProcessDetailStage stage;

  const _StageCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    final assignments = stage.assignments;
    final hasConfigBody = stage.config != null && stage.config!.isNotEmpty;
    // A service task runs on its own, so "no roles assigned" is the normal
    // state there and must not be flagged as a gap.
    final automatic = stage.isServiceTask;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stage.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              if (stage.isAuth) ...[
                const SizedBox(width: AppSpacing.sm),
                const _Pill(
                  icon: Icons.person_pin_circle_rounded,
                  label: 'مرحلة المواطن',
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniTag(
                icon: automatic
                    ? Icons.settings_suggest_rounded
                    : Icons.touch_app_rounded,
                label: automatic ? 'مرحلة تلقائية' : 'مرحلة يدوية',
                tone: _TagTone.neutral,
              ),
              if (!automatic)
                _MiniTag(
                  icon: Icons.groups_rounded,
                  label: stage.hasAssignments
                      ? 'تم تعيين الأدوار'
                      : 'لا يوجد تعيين',
                  tone: stage.hasAssignments ? _TagTone.good : _TagTone.warning,
                ),
            ],
          ),
          if (hasConfigBody) ...[
            const _SoftDivider(),
            const _SubHeader(
              icon: Icons.article_outlined,
              title: 'محتوى المرحلة',
            ),
            const SizedBox(height: AppSpacing.md),
            StageConfigView(config: stage.config!),
          ],
          if (assignments.isNotEmpty) ...[
            const _SoftDivider(),
            const _SubHeader(
              icon: Icons.badge_outlined,
              title: 'الجهات المسؤولة',
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < assignments.length; i++) ...[
              _AssignmentTile(assignment: assignments[i]),
              if (i != assignments.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

/// One responsible party. Shows the role name and where it sits in the org —
/// never the underlying role or assignment id.
class _AssignmentTile extends StatelessWidget {
  final StageAssignment assignment;

  const _AssignmentTile({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final role = assignment.role;
    final title = _title(role);
    final place = _place(role);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (place != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.corporate_fare_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _title(AssignmentRole? role) {
    final name = role?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'دور غير مُسمّى';
  }

  /// "الجهة / الإدارة" — omitted entirely when neither is known.
  static String? _place(AssignmentRole? role) {
    if (role == null) return null;
    final parts = [
      if (role.organization != null && role.organization!.trim().isNotEmpty)
        role.organization!.trim(),
      if (role.department != null && role.department!.trim().isNotEmpty)
        role.department!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.lightPrimary,
            borderRadius: AppRadius.allPill,
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SubHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightSecondary,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentMaroon),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentMaroon,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual weight of a stage tag: informational, healthy, or needs attention.
enum _TagTone { neutral, good, warning }

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final _TagTone tone;

  const _MiniTag({
    required this.icon,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _TagTone.neutral => AppColors.textSecondary,
      _TagTone.good => AppColors.success,
      _TagTone.warning => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: AppRadius.allPill,
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? background;

  const _Card({required this.child, this.borderColor, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFaint,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 46, color: AppColors.iconMuted),
          SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد تفاصيل لعرضها',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
