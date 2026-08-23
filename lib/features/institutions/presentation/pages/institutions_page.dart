import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';
import '../widgets/institution_search_bar.dart';
import '../widgets/institutions_breadcrumb.dart';
import '../widgets/institutions_header.dart';
import '../widgets/institutions_table.dart';

class InstitutionsPage extends StatefulWidget {
  const InstitutionsPage({super.key});

  @override
  State<InstitutionsPage> createState() => _InstitutionsPageState();
}

class _InstitutionsPageState extends State<InstitutionsPage> {
  late final InstitutionsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<InstitutionsBloc>()..add(const LoadInstitutions());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Container(
        color: AppColors.surfaceAlt,
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InstitutionsHeader(),
            SizedBox(height: 28),
            InstitutionsBreadcrumb(),
            InstitutionSearchBar(),
            SizedBox(height: 24),
            Expanded(child: _InstitutionsBody()),
          ],
        ),
      ),
    );
  }
}

/// يعرض حالة القائمة (تحميل / خطأ / فارغ / نجاح) ثم الجدول.
class _InstitutionsBody extends StatelessWidget {
  const _InstitutionsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstitutionsBloc, InstitutionsState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.institutions != c.institutions ||
          p.breadcrumb != c.breadcrumb ||
          p.searchQuery != c.searchQuery ||
          p.currentPage != c.currentPage ||
          p.pageSize != c.pageSize,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: AppSkeleton.table(columns: 5),
            );
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<InstitutionsBloc>().add(const LoadInstitutions()),
            );
          case RequestStatus.success:
            if (state.levelInstitutions.isEmpty) {
              final atRoot = state.breadcrumb.isEmpty;
              final searching = state.searchQuery.trim().isNotEmpty;
              final message = searching
                  ? 'لا توجد نتائج مطابقة للبحث'
                  : atRoot
                      ? 'لا توجد مؤسسات لعرضها'
                      : 'لا توجد مؤسسات تابعة لهذه المؤسسة';
              return _EmptyState(message: message);
            }
            return InstitutionsTable(state: state);
        }
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apartment_outlined,
                color: AppColors.iconMuted, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 15),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 44),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
