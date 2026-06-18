import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/process_list_bloc.dart';
import '../bloc/process_list_event.dart';
import '../widgets/process_list_view.dart';

/// Processes belonging to a single type (`admin/type/{typeId}`), reached from
/// the types grid. Hosts the "create transaction" button, which carries the
/// type forward into the wizard.
class ProcessByTypePage extends StatelessWidget {
  final int typeId;
  final String? typeName;

  const ProcessByTypePage({super.key, required this.typeId, this.typeName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProcessListBloc>()..add(LoadProcessesByType(typeId)),
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

    void openCreate() => context.go(
          '/transactions/create',
          extra: {'typeId': typeId, 'typeName': typeName},
        );

    return Container(
      color: const Color(0xffF0EFE7),
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(typeName: typeName, onCreate: openCreate),
          const SizedBox(height: 24),
          Expanded(
            child: ProcessListView(
              tab: ProcessListTab.all,
              typeId: typeId,
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
              onTap: () => context.go('/transactions'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 22, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  typeName ?? 'معاملات النوع',
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
                  'إنشاء معاملة جديدة',
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
