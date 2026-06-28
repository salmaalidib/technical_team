import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../theme/app_colors.dart';

/// منشئ موحّد لأعمدة [SfDataGrid] — يضمن نفس ستايل الرأس (خط Cairo، عريض،
/// خلفية بيج فاتحة) عبر كل جداول التطبيق.
///
/// [columnName] يجب أن يطابق اسم العمود المستخدم في خلايا [DataGridRow]
/// داخل الـ DataSource.
GridColumn buildGridColumn({
  required String columnName,
  required String label,
  double width = double.nan,
  ColumnWidthMode columnWidthMode = ColumnWidthMode.fill,
  Alignment alignment = Alignment.centerRight,
}) {
  return GridColumn(
    columnName: columnName,
    width: width,
    columnWidthMode: columnWidthMode,
    label: Container(
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: alignment,
      child: Text(
        label,
        textAlign: alignment == Alignment.center
            ? TextAlign.center
            : TextAlign.right,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    ),
  );
}
