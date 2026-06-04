import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class EmployeesGrid extends StatelessWidget {
  const EmployeesGrid({super.key});

  static const employees = [
    _EmployeeCardData(
      name: 'أحمد محمد الأحمد',
      username: 'ahmad.ahmad',
      letter: 'أ',
      department: 'دائرة التعليم الثانوي',
      section: 'شعبة المدرسين',
      role: 'موظف مختص',
    ),
    _EmployeeCardData(
      name: 'فاطمة أحمد الحسن',
      username: 'fatima.hassan',
      letter: 'ف',
      department: 'دائرة التعليم الثانوي',
      section: 'شعبة الطلاب',
      role: 'رئيس شعبة',
    ),
    _EmployeeCardData(
      name: 'محمد علي السيد',
      username: 'mohammad.alsayed',
      letter: 'م',
      department: 'دائرة التعليم الثانوي',
      section: '-',
      role: 'رئيس دائرة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1180
            ? 3
            : width >= 760
                ? 2
                : 1;

        return GridView.builder(
          itemCount: employees.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.32,
          ),
          itemBuilder: (context, index) {
            return EmployeeCard(data: employees[index]);
          },
        );
      },
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final _EmployeeCardData data;

  const EmployeeCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.primary,
                child: Text(
                  data.letter,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.name,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.username,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 5),
                    const _StatusBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'الدائرة:', value: data.department),
          const SizedBox(height: 7),
          _InfoRow(label: 'الشعبة:', value: data.section),
          const SizedBox(height: 7),
          _InfoRow(label: 'الدور:', value: data.role, asBadge: true),
          const SizedBox(height: 9),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 9),
          Row(
            children: const [
              Expanded(
                child: _CardButton(
                  icon: Icons.description_outlined,
                  label: 'المعاملات',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  icon: Icons.visibility_outlined,
                  label: 'الملف',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: _CardButton(
                  icon: Icons.edit_outlined,
                  label: 'تعديل',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  icon: Icons.account_tree_outlined,
                  label: 'الهيكل',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool asBadge;

  const _InfoRow({
    required this.label,
    required this.value,
    this.asBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: asBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'نشط',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CardButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.inputBackground,
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCardData {
  final String name;
  final String username;
  final String letter;
  final String department;
  final String section;
  final String role;

  const _EmployeeCardData({
    required this.name,
    required this.username,
    required this.letter,
    required this.department,
    required this.section,
    required this.role,
  });
}
