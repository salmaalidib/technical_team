import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import '../widgets/process_list_view.dart';

/// Complaints landing page (`admin/complaints/all`): every complaint process,
/// active and inactive. Complaints have no process type, so unlike the
/// transactions flow there is no types grid — the create button opens the
/// wizard directly in complaint mode.
class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProcessListBloc>()..add(const LoadComplaintProcesses()),
      child: const _ComplaintsView(),
    );
  }
}

class _ComplaintsView extends StatelessWidget {
  const _ComplaintsView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    // Defer to a microtask so the push happens after the current frame's
    // mouse-tracker phase, avoiding Flutter's desktop MouseTracker assertion
    // when navigating away from the hovered button.
    void openCreate() {
      final router = GoRouter.of(context);
      final bloc = context.read<ProcessListBloc>();
      Future.microtask(() async {
        final saved = await router.push<bool>('/complaints/create');
        // The wizard returns `true` after a successful save — reload so the
        // newly-created complaint shows up in the list.
        if (saved == true) bloc.add(const LoadComplaintProcesses());
      });
    }

    return BlocListener<ProcessListBloc, ProcessListState>(
      // One-shot feedback for the activate/deactivate action.
      listenWhen: (p, c) => p.activeActionStatus != c.activeActionStatus,
      listener: (context, state) {
        final message = state.activeActionStatus == RequestStatus.failure
            ? state.activeActionError
            : state.activeActionStatus == RequestStatus.success
                ? state.activeActionSuccess
                : null;
        if (message == null || message.isEmpty) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message, textAlign: TextAlign.right),
              backgroundColor: state.activeActionStatus == RequestStatus.failure
                  ? AppColors.error
                  : AppColors.primary,
            ),
          );
      },
      child: Container(
        color: const Color(0xffF0EFE7),
        padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onCreate: openCreate),
            const SizedBox(height: 24),
            const Expanded(
              child: ProcessListView(tab: ProcessListTab.complaints),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCreate;

  const _Header({required this.onCreate});

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
                const Icon(Icons.report_gmailerrorred_outlined,
                    color: AppColors.primary, size: 34),
                const SizedBox(width: 10),
                Text(
                  'الشكاوى',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'إدارة عمليات الشكاوى الفعّالة وغير الفعّالة',
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
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.add_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  'إنشاء شكوى',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
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
