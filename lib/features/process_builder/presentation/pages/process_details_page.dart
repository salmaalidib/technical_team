import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../domain/entities/process_details.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import '../widgets/process_status_badges.dart';
import '../widgets/stage_config_view.dart';

/// Full details of one process (`GET /api/process_definitions/{id}/details`):
/// header info, the validation verdict, then each stage with its assignments.
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
      color: const Color(0xffF0EFE7),
      padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go('/transactions'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<ProcessListBloc, ProcessListState>(
              buildWhen: (p, c) =>
                  p.detailsStatus != c.detailsStatus ||
                  p.details != c.details,
              builder: (context, state) {
                switch (state.detailsStatus) {
                  case RequestStatus.initial:
                  case RequestStatus.loading:
                    return const AppSkeleton.list(itemCount: 6);
                  case RequestStatus.failure:
                    return _ErrorState(
                      message: state.detailsError ?? 'حدث خطأ غير متوقع',
                      onRetry: () => context
                          .read<ProcessListBloc>()
                          .add(LoadProcessDetails(id)),
                    );
                  case RequestStatus.success:
                    final d = state.details;
                    if (d == null) {
                      return const Center(
                          child: Text('لا توجد تفاصيل لعرضها'));
                    }
                    return _DetailsBody(details: d);
                }
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
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            tooltip: 'رجوع',
          ),
          const SizedBox(width: 4),
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

  const _DetailsBody({required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ProcessHeaderCard(info: details.process),
          const SizedBox(height: 16),
          _ValidationCard(validation: details.validation),
          const SizedBox(height: 16),
          Text(
            'المراحل (${details.stages.length})',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final stage in details.stages) ...[
            _StageCard(stage: stage),
            const SizedBox(height: 12),
          ],
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApprovalBadge(
                approvalStatus: info.approvalStatus,
                isApproved: info.isApproved,
              ),
              ActiveBadge(isActive: info.isActive),
            ],
          ),
          const SizedBox(height: 16),
          _DateRow(
            startDate: info.startDate,
            endDate: info.endDate,
          ),
        ],
      ),
    );
  }
}

/// Emphasised start/end dates for the process.
class _DateRow extends StatelessWidget {
  final String? startDate;
  final String? endDate;

  const _DateRow({this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _DateChip(
          icon: Icons.event_available_outlined,
          label: 'تاريخ البدء',
          value: _fmt(startDate),
        ),
        _DateChip(
          icon: Icons.event_busy_outlined,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
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
    final color =
        valid ? const Color(0xff2E7D32) : const Color(0xffC62828);

    return _Card(
      borderColor: color.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(valid ? Icons.check_circle : Icons.error,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                valid ? 'إعداد العملية مكتمل' : 'إعداد العملية غير مكتمل',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (!valid && validation.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final err in validation.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(
                        err,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stage.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (stage.isAuth)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'مرحلة المواطن',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(
                label: stage.hasConfig ? 'يحتوي نموذجًا' : 'لا يوجد نموذج',
                ok: stage.hasConfig,
              ),
              _MiniTag(
                label:
                    stage.hasAssignments ? 'تم تعيين الأدوار' : 'لا يوجد تعيين',
                ok: stage.hasAssignments,
              ),
            ],
          ),
          if (stage.config != null && stage.config!.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'محتوى المرحلة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            StageConfigView(config: stage.config!),
          ],
          if (stage.assignments.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'التعيينات',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final a in stage.assignments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _assignmentLabel(a),
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.textPrimary),
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

  String _assignmentLabel(StageAssignment a) {
    final role = a.role;
    if (role == null) {
      return 'تعيين #${a.organizationDepartmentRolesId}';
    }
    final parts = [
      if (role.organization != null && role.organization!.isNotEmpty)
        role.organization!,
      if (role.department != null && role.department!.isNotEmpty)
        role.department!,
    ];
    final where = parts.isEmpty ? '' : ' — ${parts.join(' / ')}';
    return 'دور #${role.id}$where';
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final bool ok;

  const _MiniTag({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xff2E7D32) : const Color(0xffB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _Card({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
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
