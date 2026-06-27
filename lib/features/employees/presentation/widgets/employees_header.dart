import 'package:flutter/material.dart';
import 'package:technical_team/features/employees/presentation/widgets/create_employee_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/employees_bloc.dart';
import '../../../../shared/theme/app_colors.dart';

class EmployeesHeader extends StatelessWidget {
  const EmployeesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 18,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Text(
                  'إدارة الموظفين',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'إدارة حسابات الموظفين والهيكل الإداري',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  final bloc = context.read<EmployeesBloc>();

                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.55),
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: const CreateEmployeeDialog(),
                    ),
                  );
                },
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
                      'إضافة موظف جديد',
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
        ),
      ],
    );
  }
}

