import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';

/// عناصر تحكّم الترقيم (السابق / رقم الصفحة / التالي). تظهر فقط عند نجاح
/// تحميل القائمة ووجود أكثر من صفحة واحدة.
class EmployeesPagination extends StatelessWidget {
  const EmployeesPagination({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      buildWhen: (p, c) =>
          p.page != c.page ||
          p.totalPages != c.totalPages ||
          p.hasNextPage != c.hasNextPage ||
          p.hasPrevPage != c.hasPrevPage ||
          p.listStatus != c.listStatus,
      builder: (context, state) {
        if (state.listStatus != RequestStatus.success ||
            state.totalPages <= 1) {
          return const SizedBox.shrink();
        }

        final bloc = context.read<EmployeesBloc>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            _PageButton(
              icon: Icons.chevron_right_rounded,
              label: 'السابق',
              enabled: state.hasPrevPage,
              onTap: () => bloc.add(LoadEmployees(page: state.page - 1)),
            ),
            const SizedBox(width: 16),
            Text(
              'الصفحة ${state.page} من ${state.totalPages}'
              '  ·  ${state.total} موظف',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 16),
            _PageButton(
              icon: Icons.chevron_left_rounded,
              label: 'التالي',
              enabled: state.hasNextPage,
              trailingIcon: true,
              onTap: () => bloc.add(LoadEmployees(page: state.page + 1)),
            ),
          ],
        );
      },
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool trailingIcon;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(icon, size: 20),
      const SizedBox(width: 4),
      Text(label),
    ];

    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: trailingIcon ? children.reversed.toList() : children,
      ),
    );
  }
}
