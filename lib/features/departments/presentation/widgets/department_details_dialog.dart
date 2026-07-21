import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_overview.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';
import 'department_employee_tile.dart';
import 'department_manager_card.dart';
import 'department_stat_item.dart';

/// Shows a department's rich overview (manager / employees / stats / sections)
/// in a dialog. Replaces the old expandable card.
class DepartmentDetailsDialog extends StatelessWidget {
  final Department department;

  const DepartmentDetailsDialog({super.key, required this.department});

  static Future<void> show(BuildContext context, Department department) {
    final bloc = context.read<DepartmentsBloc>();
    // Fetch the overview on open if it isn't cached yet.
    if (!bloc.state.overviews.containsKey(department.id)) {
      bloc.add(LoadDepartmentOverview(department.id));
    }
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DepartmentDetailsDialog(department: department),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                department: department,
                onClose: () => Navigator.pop(context),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: BlocBuilder<DepartmentsBloc, DepartmentsState>(
                  buildWhen: (p, c) =>
                      p.overviews[department.id] != c.overviews[department.id] ||
                      p.loadingOverviews.contains(department.id) !=
                          c.loadingOverviews.contains(department.id),
                  builder: (context, state) {
                    if (state.loadingOverviews.contains(department.id)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: AppSkeleton.list(itemCount: 5),
                      );
                    }
                    final overview = state.overviews[department.id];
                    if (overview == null) {
                      return _RetryState(
                        onRetry: () => context
                            .read<DepartmentsBloc>()
                            .add(LoadDepartmentOverview(department.id)),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: _OverviewSection(overview: overview),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Department department;
  final VoidCallback onClose;

  const _Header({required this.department, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department.organizationName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 24, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
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
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
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

class _RetryState extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          const Text(
            'تعذّر تحميل تفاصيل القسم',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
