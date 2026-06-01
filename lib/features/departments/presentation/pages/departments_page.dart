import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';
import '../widgets/department_card.dart';
import '../widgets/departments_header.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DepartmentsBloc>()..add(const LoadDepartments()),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                DepartmentsHeader(),
                SizedBox(height: 28),
                _DepartmentsBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentsBody extends StatelessWidget {
  const _DepartmentsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsBloc, DepartmentsState>(
      buildWhen: (p, c) =>
          p.status != c.status || p.departments != c.departments,
      builder: (context, state) {
        switch (state.status) {
          case DepartmentsStatus.initial:
          case DepartmentsStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          case DepartmentsStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<DepartmentsBloc>().add(const LoadDepartments()),
            );
          case DepartmentsStatus.success:
            if (state.departments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'لا توجد أقسام لعرضها',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final department in state.departments) ...[
                  DepartmentCard(
                    key: ValueKey(department.id),
                    department: department,
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            );
        }
      },
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
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
