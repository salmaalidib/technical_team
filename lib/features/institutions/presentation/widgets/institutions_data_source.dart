import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/institution.dart';

/// مصدر بيانات جدول المؤسسات لـ [SfDataGrid].
///
/// عرض كامل (بدون ترقيم من جهة الخادم)؛ البحث يتم على جهة العميل بإعادة بناء
/// المصدر بالقائمة المُرشَّحة. عمود `#` تسلسلي حسب ترتيب القائمة الممرَّرة.
class InstitutionsDataSource extends DataGridSource {
  InstitutionsDataSource({required List<Institution> institutions}) {
    _rows = List<DataGridRow>.generate(institutions.length, (i) {
      final inst = institutions[i];
      return DataGridRow(cells: [
        DataGridCell<int>(columnName: 'number', value: i + 1),
        DataGridCell<String>(columnName: 'name', value: inst.name),
        DataGridCell<String>(
            columnName: 'location', value: inst.locationName ?? '-'),
      ]);
    });
  }

  List<DataGridRow> _rows = [];

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final muted = cell.columnName == 'location';
        return Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            cell.value.toString(),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
