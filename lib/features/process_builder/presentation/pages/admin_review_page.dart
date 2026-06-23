import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import '../widgets/process_list_view.dart';

/// Technical-team admin screen with two tabs:
///   * "مكتملة (للاعتماد)" → review-queue (approve / reject),
///   * "غير مكتملة"        → missing-stage-config (complete → wizard step 4).
class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProcessListBloc>()
        ..add(const LoadReviewQueue())
        ..add(const LoadMissingStageConfig()),
      child: const _AdminReviewView(),
    );
  }
}

class _AdminReviewView extends StatelessWidget {
  const _AdminReviewView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return DefaultTabController(
      length: 2,
      child: BlocListener<ProcessListBloc, ProcessListState>(
        listenWhen: (p, c) =>
            (p.reviewActionSuccess != c.reviewActionSuccess &&
                c.reviewActionSuccess != null) ||
            (p.reviewActionError != c.reviewActionError &&
                c.reviewActionError != null),
        listener: (context, state) {
          if (state.reviewActionSuccess != null) {
            AppSnackBar.show(context, message: state.reviewActionSuccess!);
          } else if (state.reviewActionError != null) {
            AppSnackBar.show(context,
                message: state.reviewActionError!, isError: true);
          }
        },
        child: Container(
          color: const Color(0xffF0EFE7),
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اعتماد المعاملات',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'راجع المعاملات المكتملة للموافقة على نشرها، أو أكمل تهيئة المعاملات الناقصة.',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  tabs: [
                    Tab(text: 'مكتملة (للاعتماد)'),
                    Tab(text: 'غير مكتملة'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Expanded(
                child: TabBarView(
                  children: [
                    ProcessListView(tab: ProcessListTab.review),
                    ProcessListView(tab: ProcessListTab.missingConfig),
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
