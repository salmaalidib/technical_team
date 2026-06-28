import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/employee.dart';
import 'employee_action_button.dart';
import 'employee_status_badge.dart';

/// مصدر بيانات جدول الموظفين لـ [SfDataGrid].
///
/// يحوّل كل [Employee] إلى صف، ويعيد رسم خلايا الحالة (badge) والإجراءات
/// (عرض/تعديل) بشكل مخصّص في [buildRow]. تُمرَّر دوال الإجراءات من الجدول.
class EmployeesDataSource extends DataGridSource {
  EmployeesDataSource({
    required List<Employee> employees,
    required this.onView,
    required this.onEdit,
  }) {
    updateData(employees);
  }

  final void Function(Employee employee) onView;
  final void Function(Employee employee) onEdit;

  List<DataGridRow> _rows = [];

  /// يعيد بناء الصفوف من قائمة موظفي الصفحة الحالية ويُحدّث الجدول.
  /// يُستدعى عند وصول صفحة جديدة من الخادم دون إنشاء مصدر جديد، حفاظاً على
  /// تزامن حالة الـ pager.
  void updateData(List<Employee> employees) {
    _rows = employees
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'name', value: e.fullName),
              DataGridCell<String>(columnName: 'userName', value: e.userName),
              DataGridCell<String>(columnName: 'email', value: e.email),
              DataGridCell<String>(
                  columnName: 'phone', value: e.phoneNumber),
              DataGridCell<String>(
                  columnName: 'department', value: e.department?.name ?? '-'),
              DataGridCell<String>(
                  columnName: 'role', value: e.role?.name ?? '-'),
              DataGridCell<bool>(columnName: 'status', value: e.isActive),
              // نُبقي الكائن كاملاً ليتمكّن صف الإجراءات من تمريره للحوارات.
              DataGridCell<Employee>(columnName: 'actions', value: e),
            ]))
        .toList();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  /// ترقيم من جهة الخادم: الصفوف الحالية تمثّل صفحة الخادم الحالية بالكامل،
  /// لذا نقبل التنقّل دائماً. الجلب الفعلي للصفحة الجديدة يتم عبر الـ BLoC
  /// في `onPageNavigationEnd` ثم يُعاد بناء هذا المصدر بالبيانات الجديدة.
  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    return true;
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        switch (cell.columnName) {
          case 'status':
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: EmployeeStatusBadge(isActive: cell.value as bool),
            );
          case 'actions':
            final employee = cell.value as Employee;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                EmployeeActionButton(
                  icon: Icons.visibility_outlined,
                  backgroundColor: AppColors.lightPrimary,
                  iconColor: AppColors.primary,
                  onTap: () => onView(employee),
                ),
                const SizedBox(width: 6),
                EmployeeActionButton(
                  icon: Icons.edit_outlined,
                  backgroundColor: AppColors.inputBackground,
                  iconColor: AppColors.secondary,
                  onTap: () => onEdit(employee),
                ),
              ],
            );
          case 'name':
            return _cell(
              cell.value.toString(),
              bold: true,
            );
          case 'userName':
          case 'email':
          case 'phone':
            return _cell(cell.value.toString(), muted: true);
          default:
            return _cell(cell.value.toString());
        }
      }).toList(),
    );
  }

  Widget _cell(String text, {bool bold = false, bool muted = false}) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          height: 1.4,
          color: muted ? AppColors.textSecondary : AppColors.textPrimary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
