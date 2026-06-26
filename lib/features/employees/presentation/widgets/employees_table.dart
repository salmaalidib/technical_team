import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/employee.dart';
import 'employee_action_button.dart';
import 'employee_dialogs.dart';
import 'employee_status_badge.dart';

class EmployeesTable extends StatelessWidget {
  final List<Employee> employees;

  const EmployeesTable({super.key, required this.employees});

  static const double minTableWidth = 1320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, minTableWidth);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _EmployeesTableHeader(),
                  for (final employee in employees)
                    _EmployeesTableRow(
                      key: ValueKey(employee.id),
                      employee: employee,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmployeesTableHeader extends StatelessWidget {
  const _EmployeesTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          _HeaderCell('اسم\nالموظف', flex: 11),
          _HeaderCell('اسم المستخدم', flex: 13),
          _HeaderCell('البريد الإلكتروني', flex: 14),
          _HeaderCell('الهاتف', flex: 10),
          _HeaderCell('الدائرة', flex: 10),
          _HeaderCell('الدور', flex: 9),
          _HeaderCell('الحالة', flex: 8),
          _HeaderCell('الإجراءات', flex: 16, alignCenter: true),
        ],
      ),
    );
  }
}

class _EmployeesTableRow extends StatelessWidget {
  final Employee employee;

  const _EmployeesTableRow({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _BodyCell(employee.fullName, flex: 11, isBold: true),
          _BodyCell(employee.userName, flex: 13, muted: true),
          _BodyCell(employee.email, flex: 14, muted: true),
          _BodyCell(employee.phoneNumber, flex: 10, muted: true),
          _BodyCell(employee.department?.name ?? '-', flex: 10),
          Expanded(
            flex: 9,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  employee.role?.name ?? '-',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Align(
              alignment: Alignment.centerRight,
              child: EmployeeStatusBadge(isActive: employee.isActive),
            ),
          ),
          Expanded(
            flex: 16,
            child: _ActionsCell(employee: employee),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignCenter;

  const _HeaderCell(
    this.text, {
    required this.flex,
    this.alignCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignCenter ? TextAlign.center : TextAlign.right,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool muted;
  final bool isBold;

  const _BodyCell(
    this.text, {
    required this.flex,
    this.muted = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              height: 1.45,
            ),
      ),
    );
  }
}

class _ActionsCell extends StatelessWidget {
  final Employee employee;

  const _ActionsCell({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        EmployeeActionButton(
          icon: Icons.visibility_outlined,
          backgroundColor: AppColors.lightPrimary,
          iconColor: AppColors.primary,
          onTap: () => showEmployeeDetails(context, employee),
        ),
        const SizedBox(width: 6),
        EmployeeActionButton(
          icon: Icons.edit_outlined,
          backgroundColor: AppColors.inputBackground,
          iconColor: AppColors.secondary,
          onTap: () => showEmployeeEditor(context, employee),
        ),
      ],
    );
  }
}
