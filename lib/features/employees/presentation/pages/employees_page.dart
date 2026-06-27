import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import '../widgets/employees_header.dart';
import '../widgets/employees_pagination.dart';
import '../widgets/employees_search_card.dart';
import '../widgets/employees_table.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  late final EmployeesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<EmployeesBloc>()..add(const LoadEmployees());
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
      child: BlocListener<EmployeesBloc, EmployeesState>(
        listenWhen: (p, c) => p.updateStatus != c.updateStatus,
        listener: (context, state) {
          if (state.updateStatus == FormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تعديل بيانات الموظف بنجاح'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          color: const Color(0xffF0EFE7),
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmployeesHeader(),
                SizedBox(height: 28),
                EmployeesSearchCard(),
                SizedBox(height: 24),
                _EmployeesBody(),
                SizedBox(height: 20),
                EmployeesPagination(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// يعرض حالة القائمة (تحميل / خطأ / فارغ / نجاح) ثم الجدول.
class _EmployeesBody extends StatelessWidget {
  const _EmployeesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      buildWhen: (p, c) =>
          p.listStatus != c.listStatus ||
          p.employees != c.employees ||
          p.updatingId != c.updatingId,
      builder: (context, state) {
        switch (state.listStatus) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          case RequestStatus.failure:
            return _ErrorState(
              message: state.listError ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<EmployeesBloc>().add(const LoadEmployees()),
            );
          case RequestStatus.success:
            if (state.employees.isEmpty) {
              return const _EmptyState();
            }
            return EmployeesTable(employees: state.employees);
        }
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Text(
          'لا يوجد موظفون لعرضهم',
          style: TextStyle(color: Colors.black54, fontSize: 15),
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
