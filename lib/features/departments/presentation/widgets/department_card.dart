import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_overview.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';
import 'department_employee_tile.dart';
import 'department_manager_card.dart';
import 'department_stat_item.dart';

class DepartmentCard extends StatefulWidget {
  final Department department;

  const DepartmentCard({super.key, required this.department});

  @override
  State<DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<DepartmentCard> {
  bool isExpanded = false;

  int get _id => widget.department.id;

  void _toggleExpand() {
    setState(() => isExpanded = !isExpanded);
    if (isExpanded) {
      final bloc = context.read<DepartmentsBloc>();
      if (!bloc.state.overviews.containsKey(_id)) {
        bloc.add(LoadDepartmentOverview(_id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final department = widget.department;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded ? AppColors.primary : AppColors.border,
          width: isExpanded ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _Header(
            department: department,
            isExpanded: isExpanded,
            onToggleExpand: _toggleExpand,
          ),
          if (isExpanded) ...[
            const SizedBox(height: 24),
            BlocBuilder<DepartmentsBloc, DepartmentsState>(
              buildWhen: (p, c) =>
                  p.overviews[_id] != c.overviews[_id] ||
                  p.loadingOverviews.contains(_id) !=
                      c.loadingOverviews.contains(_id),
              builder: (context, state) {
                if (state.loadingOverviews.contains(_id)) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final overview = state.overviews[_id];
                if (overview == null) {
                  return const SizedBox.shrink();
                }
                return _OverviewSection(overview: overview);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Department department;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _Header({
    required this.department,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_left_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apartment_outlined,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                department.name,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                department.organizationName ?? '—',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StatusToggle(department: department),
      ],
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final Department department;

  const _StatusToggle({required this.department});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsBloc, DepartmentsState>(
      buildWhen: (p, c) =>
          p.togglingIds.contains(department.id) !=
          c.togglingIds.contains(department.id),
      builder: (context, state) {
        final busy = state.togglingIds.contains(department.id);
        final active = department.isActive;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (active ? AppColors.primary : AppColors.textSecondary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                active ? 'مفعّل' : 'معطّل',
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            busy
                ? const SizedBox(
                    width: 40,
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Switch(
                    value: active,
                    activeColor: AppColors.primary,
                    onChanged: (_) => context
                        .read<DepartmentsBloc>()
                        .add(ToggleDepartmentStatus(department.id)),
                  ),
          ],
        );
      },
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final DepartmentOverview overview;

  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DepartmentStatItem(
                value: '${overview.transactionsCount}',
                label: 'معاملة',
                color: AppColors.primary,
              ),
              const SizedBox(width: 42),
              DepartmentStatItem(
                value: '${overview.employeesCount}',
                label: 'موظف',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 42),
              DepartmentStatItem(
                value: '${overview.sectionsCount}',
                label: 'شعبة',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // Manager
        if (overview.manager != null)
          DepartmentManagerCard(
            name: overview.manager!.name,
            title: overview.manager!.role ?? 'مدير القسم',
          )
        else
          const _EmptyHint(text: 'لا يوجد مدير معيّن لهذا القسم'),
        const SizedBox(height: 26),

        // Employees
        _SectionTitle(
          icon: Icons.group_outlined,
          title: 'موظفو القسم (${overview.employeesCount})',
        ),
        const SizedBox(height: 18),
        if (overview.employees.isEmpty)
          const _EmptyHint(text: 'لا يوجد موظفون')
        else
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 42,
              runSpacing: 18,
              alignment: WrapAlignment.end,
              children: [
                for (final e in overview.employees)
                  DepartmentEmployeeTile(
                    name: e.name,
                    jobTitle: e.role ?? 'موظف',
                    letter: e.name.isNotEmpty ? e.name.substring(0, 1) : '?',
                  ),
              ],
            ),
          ),
        const SizedBox(height: 30),

        // Sections (child departments)
        _SectionTitle(
          icon: Icons.folder_outlined,
          title: 'الشعب التابعة (${overview.sectionsCount})',
        ),
        const SizedBox(height: 18),
        if (overview.sections.isEmpty)
          const _EmptyHint(text: 'لا توجد شعب تابعة')
        else
          Column(
            children: [
              for (final s in overview.sections) ...[
                _SectionTile(section: s),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  final DepartmentSection section;

  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xffFAF9F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.folder_outlined,
              color: AppColors.secondary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              section.name,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (section.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              section.isActive ? 'مفعّل' : 'معطّل',
              style: TextStyle(
                color: section.isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}
