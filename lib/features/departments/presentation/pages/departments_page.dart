import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../widgets/departments_header.dart';
import '../widgets/department_card.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DepartmentsHeader(),
            SizedBox(height: 28),
            DepartmentCard(),
            SizedBox(height: 22),
            DepartmentCard(
              title: 'دائرة الشؤون الإدارية',
              managerName: 'عمر يوسف الجاسم',
              managerTitle: 'رئيس الدائرة',
              employeesCount: '1',
              sectionsCount: '1',
              transactionsCount: '1',
              sectionName: 'شعبة الموارد البشرية',
            ),
          ],
        ),
      ),
    );
  }
}