import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../bloc/process_list_state.dart';
import '../widgets/process_animations.dart';
import '../widgets/process_list_view.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Processes belonging to a single type (`admin/type/{typeId}`), reached from
/// the types grid. Hosts the "create transaction" button, which carries the
/// type forward into the wizard, and splits the type's processes into
/// "فعّالة" / "غير فعّالة" tabs — both fed by the one `admin/type/{typeId}`
/// response, with per-row activation through `PATCH admin/{id}/status`.
class ProcessByTypePage extends StatelessWidget {
  final int typeId;
  final String? typeName;

  const ProcessByTypePage({super.key, required this.typeId, this.typeName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProcessListBloc>()..add(LoadProcessesByType(typeId)),
      child: _ProcessByTypeView(typeId: typeId, typeName: typeName),
    );
  }
}

class _ProcessByTypeView extends StatelessWidget {
  final int typeId;
  final String? typeName;

  const _ProcessByTypeView({required this.typeId, this.typeName});

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
        final saved = await router.push<bool>(
          '/transactions/create',
          extra: {'typeId': typeId, 'typeName': typeName},
        );
        // The wizard returns `true` after a successful save — reload so the
        // newly-created process shows up in this type's list.
        if (saved == true) bloc.add(LoadProcessesByType(typeId));
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
      child: DefaultTabController(
        length: 2,
        child: Container(
          color: AppColors.surfaceAlt,
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppEnterHeader(
                child: _Header(typeName: typeName, onCreate: openCreate),
              ),
              const SizedBox(height: 20),
              const AppEnterHeader(index: 1, child: _ActiveTabs()),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    ProcessListView(
                      tab: ProcessListTab.activeOnly,
                      typeId: typeId,
                    ),
                    ProcessListView(
                      tab: ProcessListTab.inactiveOnly,
                      typeId: typeId,
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

/// The "فعّالة" / "غير فعّالة" switcher. Both tabs read the same
/// `admin/type/{typeId}` payload, partitioned locally on `is_active`.
class _ActiveTabs extends StatelessWidget {
  const _ActiveTabs();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      // The parent Column stretches its children, so a Row with a min main-axis
      // size is what keeps the pill box hugging its two tabs instead of
      // spanning the full page width.
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: AppColors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelPadding: const EdgeInsets.symmetric(horizontal: 22),
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(height: 42, text: 'المعاملات الفعّالة'),
                Tab(height: 42, text: 'المعاملات غير الفعّالة'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? typeName;
  final VoidCallback onCreate;

  const _Header({required this.typeName, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/transactions'),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                // زر رجوع في واجهة RTL: يشير نحو اليمين.
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  typeName ?? 'معاملات النوع',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل معاملات هذا النوع',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
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
                  'إنشاء معاملة جديدة',
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
