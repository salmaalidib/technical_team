import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/admin_process_item.dart';
import '../../domain/entities/review_queue_item.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import 'process_status_badges.dart';

enum ProcessListTab { all, review }

/// One tab body: a list of processes from either `admin/type/{typeId}` (all) or
/// `admin/review-queue` (review), tapping a row opens its details page.
///
/// For the "all" tab, [typeId] selects which type to load (`0` = every type);
/// the reload action re-issues the matching request.
class ProcessListView extends StatelessWidget {
  final ProcessListTab tab;
  final int typeId;

  const ProcessListView({super.key, required this.tab, this.typeId = 0});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessListBloc, ProcessListState>(
      buildWhen: (p, c) => tab == ProcessListTab.all
          ? (p.allStatus != c.allStatus || p.allProcesses != c.allProcesses)
          : (p.reviewStatus != c.reviewStatus || p.reviewQueue != c.reviewQueue),
      builder: (context, state) {
        final status =
            tab == ProcessListTab.all ? state.allStatus : state.reviewStatus;
        final error =
            tab == ProcessListTab.all ? state.allError : state.reviewError;

        switch (status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestStatus.failure:
            return _ErrorState(
              message: error ?? 'حدث خطأ غير متوقع',
              onRetry: () => _reload(context),
            );
          case RequestStatus.success:
            return _list(context, state);
        }
      },
    );
  }

  void _reload(BuildContext context) {
    final bloc = context.read<ProcessListBloc>();
    if (tab == ProcessListTab.review) {
      bloc.add(const LoadReviewQueue());
    } else {
      bloc.add(typeId == 0
          ? const LoadAllProcesses()
          : LoadProcessesByType(typeId));
    }
  }

  Widget _list(BuildContext context, ProcessListState state) {
    final count = tab == ProcessListTab.all
        ? state.allProcesses.length
        : state.reviewQueue.length;

    if (count == 0) {
      return Center(
        child: Text(
          tab == ProcessListTab.all
              ? 'لا توجد معاملات لعرضها'
              : 'لا توجد معاملات بانتظار المراجعة',
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(context),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (tab == ProcessListTab.all) {
            return _AdminProcessCard(item: state.allProcesses[i]);
          }
          return _ReviewItemCard(item: state.reviewQueue[i]);
        },
      ),
    );
  }
}

void _openDetails(BuildContext context, int id) =>
    context.go('/transactions/$id');

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

/// Card for the "review queue" tab — backed by [ReviewQueueItem].
class _ReviewItemCard extends StatelessWidget {
  final ReviewQueueItem item;

  const _ReviewItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () => _openDetails(context, item.id),
      title: item.name,
      subtitle: null,
      badges: [
        ApprovalBadge(approvalStatus: item.status, isApproved: item.isApproved),
        ActiveBadge(isActive: item.isActive),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final List<Widget> badges;

  const _CardShell({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.badges,
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
            child: Row(
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
                const Icon(Icons.chevron_left, color: AppColors.textSecondary),
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
