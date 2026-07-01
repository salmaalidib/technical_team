import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';

/// Clickable drill-down trail: "الرئيسية › قسم › شعبة". Only shown when the
/// user has navigated below the root level.
class DepartmentsBreadcrumb extends StatelessWidget {
  const DepartmentsBreadcrumb({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsBloc, DepartmentsState>(
      buildWhen: (p, c) => p.breadcrumb != c.breadcrumb,
      builder: (context, state) {
        if (state.breadcrumb.isEmpty) return const SizedBox.shrink();

        final bloc = context.read<DepartmentsBloc>();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 6,
            children: [
              _Crumb(
                label: 'الرئيسية',
                icon: Icons.home_outlined,
                isCurrent: false,
                onTap: () => bloc.add(const NavigateToCrumb(-1)),
              ),
              for (var i = 0; i < state.breadcrumb.length; i++) ...[
                const _Separator(),
                _Crumb(
                  label: state.breadcrumb[i].name,
                  isCurrent: i == state.breadcrumb.length - 1,
                  onTap: i == state.breadcrumb.length - 1
                      ? null
                      : () => bloc.add(NavigateToCrumb(i)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Crumb extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _Crumb({
    required this.label,
    this.icon,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.primary : AppColors.textSecondary;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_left_rounded,
          size: 20, color: AppColors.textSecondary),
    );
  }
}
