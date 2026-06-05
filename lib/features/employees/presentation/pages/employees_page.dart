import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../widgets/employees_grid.dart';
import '../widgets/employees_header.dart';
import '../widgets/employees_search_card.dart';
import '../widgets/employees_table.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  bool isGridView = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeesBloc>()..add(const LoadEmployeeFormData()),
      child: Container(
        color: const Color(0xffF0EFE7),
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmployeesHeader(
                isGridView: isGridView,
                onGridTap: () => setState(() => isGridView = true),
                onTableTap: () => setState(() => isGridView = false),
              ),
              const SizedBox(height: 28),
              const EmployeesSearchCard(),
              const SizedBox(height: 24),
              isGridView ? const EmployeesGrid() : const EmployeesTable(),
            ],
          ),
        ),
      ),
    );
  }
}