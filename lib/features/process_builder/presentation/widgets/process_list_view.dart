import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/admin_process_item.dart';
import '../../domain/entities/missing_config_item.dart';
import '../../domain/entities/review_queue_item.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import 'process_status_badges.dart';

enum ProcessListTab { all, review, missingConfig }

/// One tab body: a list of processes from one of three sources —
///   * [all]           → `admin/type/{typeId}` (tapping a row opens details),
///   * [review]        → `admin/review-queue` (approve / reject buttons),
///   * [missingConfig] → `admin/missing-stage-config` (complete button → step 4).
class ProcessListView extends StatelessWidget {
  final ProcessListTab tab;
  final int typeId;

  const ProcessListView({super.key, required this.tab, this.typeId = 0});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessListBloc, ProcessListState>(
      buildWhen: (p, c) => _statusOf(p) != _statusOf(c) || _listChanged(p, c),
      builder: (context, state) {
        switch (_statusOf(state)) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestStatus.failure:
            return _ErrorState(
              message: _errorOf(state) ?? 'حدث خطأ غير متوقع',
              onRetry: () => _reload(context),
            );
          case RequestStatus.success:
            return _list(context, state);
        }
      },
    );
  }

  RequestStatus _statusOf(ProcessListState s) {
    switch (tab) {
      case ProcessListTab.all:
        return s.allStatus;
      case ProcessListTab.review:
        return s.reviewStatus;
      case ProcessListTab.missingConfig:
        return s.missingStatus;
    }
  }

  String? _errorOf(ProcessListState s) {
    switch (tab) {
      case ProcessListTab.all:
        return s.allError;
      case ProcessListTab.review:
        return s.reviewError;
      case ProcessListTab.missingConfig:
        return s.missingError;
    }
  }

  bool _listChanged(ProcessListState p, ProcessListState c) {
    switch (tab) {
      case ProcessListTab.all:
        return p.allProcesses != c.allProcesses;
      case ProcessListTab.review:
        return p.reviewQueue != c.reviewQueue ||
            p.reviewActionStatus != c.reviewActionStatus;
      case ProcessListTab.missingConfig:
        return p.missingItems != c.missingItems;
    }
  }

  void _reload(BuildContext context) {
    final bloc = context.read<ProcessListBloc>();
    switch (tab) {
      case ProcessListTab.all:
        bloc.add(typeId == 0
            ? const LoadAllProcesses()
            : LoadProcessesByType(typeId));
        break;
      case ProcessListTab.review:
        bloc.add(const LoadReviewQueue());
        break;
      case ProcessListTab.missingConfig:
        bloc.add(const LoadMissingStageConfig());
        break;
    }
  }

  int _count(ProcessListState s) {
    switch (tab) {
      case ProcessListTab.all:
        return s.allProcesses.length;
      case ProcessListTab.review:
        return s.reviewQueue.length;
      case ProcessListTab.missingConfig:
        return s.missingItems.length;
    }
  }

  String get _emptyText {
    switch (tab) {
      case ProcessListTab.all:
        return 'لا توجد معاملات لعرضها';
      case ProcessListTab.review:
        return 'لا توجد معاملات مكتملة بانتظار الاعتماد';
      case ProcessListTab.missingConfig:
        return 'لا توجد معاملات غير مكتملة';
    }
  }

  Widget _list(BuildContext context, ProcessListState state) {
    if (_count(state) == 0) {
      return Center(
        child: Text(
          _emptyText,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(context),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _count(state),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _card(context, state, i),
      ),
    );
  }

  Widget _card(BuildContext context, ProcessListState state, int i) {
    switch (tab) {
      case ProcessListTab.all:
        return _AdminProcessCard(item: state.allProcesses[i]);
      case ProcessListTab.review:
        return _ReviewItemCard(
          item: state.reviewQueue[i],
          actionStatus: state.reviewActionStatus,
          actingId: state.reviewActionId,
        );
      case ProcessListTab.missingConfig:
        return _MissingItemCard(item: state.missingItems[i]);
    }
  }
}

void _openDetails(BuildContext context, int id) =>
    context.push('/transactions/$id');

/// Opens the wizard in complete-mode (step 4) for an existing process.
void _openComplete(BuildContext context, int id) => context.push(
      '/transactions/create',
      extra: {'existingProcessId': id},
    );

/// Card for the "all" tab — backed by [AdminProcessItem].
class _AdminProcessCard extends StatelessWidget {
  final AdminProcessItem item;

  const _AdminProcessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () => _openDetails(context, item.processId),
      title: item.name,
      subtitle: item.code,
      badges: [
        ApprovalBadge(approvalStatus: item.approvalStatus),
        ActiveBadge(isActive: item.isActive),
      ],
    );
  }
}

/// Card for the "review queue" tab — completed processes awaiting approval.
/// Carries approve (publish) and reject buttons.
class _ReviewItemCard extends StatelessWidget {
  final ReviewQueueItem item;
  final RequestStatus actionStatus;
  final int? actingId;

  const _ReviewItemCard({
    required this.item,
    required this.actionStatus,
    required this.actingId,
  });

  @override
  Widget build(BuildContext context) {
    final isActing =
        actionStatus == RequestStatus.loading && actingId == item.id;

    return _CardShell(
      onTap: () => _openDetails(context, item.id),
      title: item.name,
      subtitle: null,
      badges: [
        ApprovalBadge(approvalStatus: item.status, isApproved: item.isApproved),
        ActiveBadge(isActive: item.isActive),
      ],
      footer: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: _ActionButton(
              label: 'موافقة على النشر',
              icon: Icons.check_rounded,
              color: AppColors.primary,
              loading: isActing,
              onPressed: isActing
                  ? null
                  : () => _confirmAndReview(context, approve: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'رفض',
              icon: Icons.close_rounded,
              color: AppColors.error,
              outlined: true,
              loading: false,
              onPressed: isActing
                  ? null
                  : () => _confirmAndReview(context, approve: false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndReview(
    BuildContext context, {
    required bool approve,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(approve ? 'الموافقة على النشر' : 'رفض المعاملة'),
          content: Text(
            approve
                ? 'سيتم اعتماد المعاملة «${item.name}» ونشرها. متابعة؟'
                : 'سيتم رفض المعاملة «${item.name}». متابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: approve ? AppColors.primary : AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(approve ? 'موافقة' : 'رفض'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      context
          .read<ProcessListBloc>()
          .add(ReviewProcessRequested(item.id, approve: approve));
    }
  }
}

/// Card for the "missing stage config" tab — incomplete processes. Carries a
/// "complete" button that opens the wizard at step 4.
class _MissingItemCard extends StatelessWidget {
  final MissingConfigItem item;

  const _MissingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final missing = item.stagesMissingConfigCount;
    final total = item.stagesTotalCount;
    final progressText = total == 0
        ? 'لا توجد مراحل بعد'
        : 'ناقص $missing من $total مرحلة';

    return _CardShell(
      onTap: () => _openComplete(context, item.id),
      title: item.name,
      subtitle: progressText,
      badges: [
        ApprovalBadge(approvalStatus: item.status, isApproved: item.isApproved),
        ActiveBadge(isActive: item.isActive),
      ],
      footer: _ActionButton(
        label: 'إكمال التهيئة',
        icon: Icons.edit_outlined,
        color: AppColors.primary,
        loading: false,
        onPressed: () => _openComplete(context, item.id),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool outlined;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          );

    return SizedBox(
      height: 44,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: child,
            ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final List<Widget> badges;
  final Widget? footer;

  const _CardShell({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.badges,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: badges),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        color: AppColors.textSecondary),
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
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
