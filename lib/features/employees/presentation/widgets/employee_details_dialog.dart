import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class EmployeeDetailsDialog extends StatelessWidget {
  final String firstName;
  final String fatherName;
  final String motherName;
  final String lastName;
  final String nationalId;
  final String username;
  final String email;
  final String phone;
  final String department;
  final String section;
  final String role;

  const EmployeeDetailsDialog({
    super.key,
    required this.firstName,
    required this.fatherName,
    required this.motherName,
    required this.lastName,
    required this.nationalId,
    required this.username,
    required this.email,
    required this.phone,
    required this.department,
    required this.section,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Row(
                  children: [
                    Text(
                      'معلومات الموظف',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      _InfoRow('الاسم الأول', firstName),
                      _InfoRow('اسم الأب', fatherName),
                      _InfoRow('اسم الأم', motherName),
                      _InfoRow('الاسم الأخير', lastName),
                      _InfoRow('الرقم الوطني', nationalId),
                      _InfoRow('اسم المستخدم', username),
                      _InfoRow('البريد الإلكتروني', email),
                      _InfoRow('رقم الهاتف', phone),
                      _InfoRow('القسم / الدائرة', department),
                      _InfoRow('الشعبة', section),
                      _InfoRow('الدور', role),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffFAF9F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}