import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';
import '../widgets/department_search_bar.dart';
import '../widgets/departments_breadcrumb.dart';
import '../widgets/departments_header.dart';
import '../widgets/departments_table.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  late final DepartmentsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<DepartmentsBloc>()..add(const LoadDepartments());
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
      child: BlocListener<DepartmentsBloc, DepartmentsState>(
        listenWhen: (p, c) => p.actionError != c.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            AppSnackBar.show(
              context,
              message: state.actionError!,
              isError: true,
            );
          }
        },
        child: Container(
          color: const Color(0xffF0EFE7),
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DepartmentsHeader(),
              SizedBox(height: 28),
              DepartmentsBreadcrumb(),
              DepartmentSearchBar(),
              SizedBox(height: 24),
              Expanded(child: _DepartmentsBody()),
            ],
          ),
        ),
      ),
    );
  }
}

/// يعرض حالة القائمة (تحميل / خطأ / فارغ / نجاح) ثم الجدول.
class _DepartmentsBody extends StatelessWidget {
  const _DepartmentsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsBloc, DepartmentsState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.departments != c.departments ||
          p.breadcrumb != c.breadcrumb ||
          p.searchQuery != c.searchQuery ||
          p.currentPage != c.currentPage ||
          p.pageSize != c.pageSize ||
          p.togglingIds != c.togglingIds,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<DepartmentsBloc>().add(const LoadDepartments()),
            );
          case RequestStatus.success:
            if (state.levelDepartments.isEmpty) {
              final atRoot = state.breadcrumb.isEmpty;
              final searching = state.searchQuery.trim().isNotEmpty;
              final message = searching
                  ? 'لا توجد نتائج مطابقة للبحث'
                  : atRoot
                      ? 'لا توجد أقسام لعرضها'
                      : 'لا توجد شعب تابعة لهذا القسم';
              return _EmptyState(message: message);
            }
            return DepartmentsTable(state: state);
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
            const Icon(Icons.folder_off_outlined,
                color: Colors.black26, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
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
              style: const TextStyle(color: Colors.black54, fontSize: 15),
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
