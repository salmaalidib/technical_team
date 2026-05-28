import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import 'department_employee_tile.dart';
import 'department_manager_card.dart';
import 'department_section_card.dart';
import 'department_stat_item.dart';

class DepartmentCard extends StatefulWidget {
  final String title;
  final String managerName;
  final String managerTitle;
  final String employeesCount;
  final String sectionsCount;
  final String transactionsCount;
  final String sectionName;

  const DepartmentCard({
    super.key,
    this.title = 'دائرة التعليم الثانوي',
    this.managerName = 'محمد علي السيد',
    this.managerTitle = 'رئيس الدائرة',
    this.employeesCount = '6',
    this.sectionsCount = '2',
    this.transactionsCount = '8',
    this.sectionName = 'شعبة المدرسين',
  });

  @override
  State<DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<DepartmentCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;

              final stats = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DepartmentStatItem(
                      value: widget.transactionsCount,
                      label: 'معاملة',
                      color: AppColors.primary),
                  const SizedBox(width: 42),
                  DepartmentStatItem(
                      value: widget.employeesCount,
                      label: 'موظف',
                      color: AppColors.secondary),
                  const SizedBox(width: 42),
                  DepartmentStatItem(
                      value: widget.sectionsCount,
                      label: 'شعبة',
                      color: AppColors.primary),
                ],
              );

              final titleSide = Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => isExpanded = !isExpanded),
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
                            : Icons.chevron_right_rounded,
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
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مديرية التربية الرئيسية',
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerRight, child: titleSide),
                    const SizedBox(height: 18),
                    Align(alignment: Alignment.centerLeft, child: stats),
                  ],
                );
              }

              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  stats,
                  const Spacer(),
                  Flexible(
                      child: Align(
                          alignment: Alignment.centerRight, child: titleSide)),
                ],
              );
            },
          ),
          if (isExpanded) ...[
            const SizedBox(height: 28),
            DepartmentManagerCard(
              name: widget.managerName,
              title: widget.managerTitle,
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              icon: Icons.group_outlined,
              title: 'موظفو الدائرة (${widget.employeesCount})',
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 42,
                runSpacing: 18,
                alignment: WrapAlignment.end,
                children: const [
                  DepartmentEmployeeTile(
                    name: 'أحمد محمود',
                    jobTitle: 'موجه اختصاصي',
                    letter: 'أ',
                  ),
                  DepartmentEmployeeTile(
                    name: 'فاطمة حسن',
                    jobTitle: 'موظف إداري',
                    letter: 'ف',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _SectionTitle(
              icon: Icons.folder_outlined,
              title: 'الشعب التابعة (${widget.sectionsCount})',
            ),
            const SizedBox(height: 18),
            DepartmentSectionCard(
              sectionName: widget.sectionName,
              managerName: 'خالد أحمد النور',
              employeesCount: '2',
              transactionsCount: '4',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

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
