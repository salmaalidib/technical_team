import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../bloc/employees_bloc.dart';
import 'employee_details_dialog.dart';
import 'update_employee_dialog.dart';

/// أدوات مشتركة لفتح حواري العرض/التعديل من الجدول والـ grid، مع الحفاظ على
/// تمرير الـ [EmployeesBloc] الحالي إلى الحوار (لأن نموذج التعديل يستهلكه).
void showEmployeeDetails(BuildContext context, Employee e) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => EmployeeDetailsDialog(
      firstName: e.firstName,
      fatherName: e.fatherName,
      motherName: e.motherName,
      lastName: e.lastName,
      nationalId: e.nationalId,
      username: e.userName,
      email: e.email,
      phone: e.phoneNumber,
      department: e.department?.name ?? '-',
      section: e.department?.name ?? '-',
      role: e.role?.name ?? '-',
    ),
  );
}

void showEmployeeEditor(BuildContext context, Employee e) {
  final bloc = context.read<EmployeesBloc>();
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: UpdateEmployeeDialog(employee: e),
    ),
  );
}
