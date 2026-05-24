import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'آخر المعاملات',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 18),
          _TransactionRow(
            title: 'تفعيل مدرسة',
            department: 'دائرة الأبنية المدرسية',
            status: 'قيد المعالجة',
          ),
          _TransactionRow(
            title: 'نقل شعبة',
            department: 'شؤون الطلاب',
            status: 'بانتظار الموافقة',
          ),
          _TransactionRow(
            title: 'اعتماد دوام مدرسة',
            department: 'التعليم الأساسي',
            status: 'مكتملة',
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String title;
  final String department;
  final String status;

  const _TransactionRow({
    required this.title,
    required this.department,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}