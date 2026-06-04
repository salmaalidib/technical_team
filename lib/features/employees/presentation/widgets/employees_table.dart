import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:technical_team/features/employees/presentation/widgets/employee_details_dialog.dart';

import '../../../../shared/theme/app_colors.dart';
import 'employee_action_button.dart';
import 'employee_status_badge.dart';

class EmployeesTable extends StatelessWidget {
  const EmployeesTable({super.key});

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
              child: const Column(
                children: [
                  _EmployeesTableHeader(),
                  _EmployeesTableRow(
                    name: 'أحمد\nمحمد\nالأحمد',
                    username: 'ahmad.ahmad',
                    email: 'ahmad@edu.sy',
                    phone: '0944123456',
                    department: 'دائرة\nالتعليم\nالثانوي',
                    section: 'شعبة\nالمدرسين',
                    role: 'موظف\nمختص',
                  ),
                  _EmployeesTableRow(
                    name: 'فاطمة\nحسن\nالحسن',
                    username: 'fatima.hassan',
                    email: 'fatima@edu.sy',
                    phone: '0933654321',
                    department: 'دائرة\nالتعليم\nالثانوي',
                    section: 'شعبة\nالطلاب',
                    role: 'رئيس\nشعبة',
                  ),
                  _EmployeesTableRow(
                    name: 'محمد\nعلي\nالسيد',
                    username: 'mohammad.alsayed',
                    email: 'mohammad@edu.sy',
                    phone: '0955789012',
                    department: 'دائرة\nالتعليم\nالثانوي',
                    section: '-',
                    role: 'رئيس\nدائرة',
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
      child: Row(
        textDirection: TextDirection.rtl,
        children: const [
          _HeaderCell('اسم\nالموظف', flex: 11),
          _HeaderCell('اسم المستخدم', flex: 13),
          _HeaderCell('البريد الإلكتروني', flex: 14),
          _HeaderCell('الهاتف', flex: 10),
          _HeaderCell('الدائرة', flex: 10),
          _HeaderCell('الشعبة', flex: 10),
          _HeaderCell('الدور', flex: 9),
          _HeaderCell('الحالة', flex: 8),
          _HeaderCell('الإجراءات', flex: 16, alignCenter: true),
        ],
      ),
    );
  }
}

class _EmployeesTableRow extends StatelessWidget {
  final String name;
  final String username;
  final String email;
  final String phone;
  final String department;
  final String section;
  final String role;

  const _EmployeesTableRow({
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.department,
    required this.section,
    required this.role,
  });

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
          _BodyCell(name, flex: 11, isBold: true),
          _BodyCell(username, flex: 13, muted: true),
          _BodyCell(email, flex: 14, muted: true),
          _BodyCell(phone, flex: 10, muted: true),
          _BodyCell(department, flex: 10),
          _BodyCell(section, flex: 10, muted: true),
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
                  role,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          const Expanded(
            flex: 8,
            child: Align(
              alignment: Alignment.centerRight,
              child: EmployeeStatusBadge(isActive: true),
            ),
          ),
          const Expanded(
            flex: 16,
            child: _ActionsCell(),
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
  const _ActionsCell();

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
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.55),
              builder: (_) => const EmployeeDetailsDialog(
                firstName: 'أحمد',
                fatherName: 'محمد',
                motherName: 'فاطمة',
                lastName: 'الأحمد',
                nationalId: '01010101010',
                username: 'ahmad.ahmad',
                email: 'ahmad@edu.sy',
                phone: '0944123456',
                department: 'دائرة التعليم الثانوي',
                section: 'شعبة المدرسين',
                role: 'موظف مختص',
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        const EmployeeActionButton(
          icon: Icons.edit_outlined,
          backgroundColor: AppColors.inputBackground,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        const EmployeeActionButton(
          icon: Icons.vpn_key_outlined,
          backgroundColor: AppColors.inputBackground,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        const EmployeeActionButton(
          icon: Icons.block_rounded,
          backgroundColor: Color(0xffFDECEC),
          iconColor: AppColors.error,
        ),
      ],
    );
  }
}