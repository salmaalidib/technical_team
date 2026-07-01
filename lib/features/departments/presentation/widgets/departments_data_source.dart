import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/department.dart';
import 'department_action_button.dart';
import 'department_status_badge.dart';

/// مصدر بيانات جدول الأقسام لـ [SfDataGrid].
///
/// الترقيم هنا من جهة العميل: يحتفظ المصدر بكامل قائمة المستوى الحالي ويقتطع
/// شريحة الصفحة المطلوبة داخلياً في [handlePageChange]، تماشياً مع منطق
/// الـ pager. تُمرَّر دوال الإجراءات (شعب/عرض/تبديل الحالة) من الجدول.
class DepartmentsDataSource extends DataGridSource {
  DepartmentsDataSource({
    required List<Department> departments,
    required this.pageSize,
    required this.onOpenChildren,
    required this.onView,
    required this.onToggleStatus,
    required this.isToggling,
  }) {
    _all = departments;
    _buildPage(0);
  }

  final void Function(Department department) onOpenChildren;
  final void Function(Department department) onView;
  final void Function(Department department) onToggleStatus;
  final bool Function(Department department) isToggling;

  int pageSize;
  List<Department> _all = [];
  List<DataGridRow> _rows = [];

  /// يعيد بناء بيانات المصدر (عند تغيّر المستوى أو البحث) ويعود للصفحة الأولى.
  void updateData(List<Department> departments, {int? pageSize}) {
    _all = departments;
    if (pageSize != null) this.pageSize = pageSize;
    _buildPage(0);
    notifyListeners();
  }

  void _buildPage(int pageIndex) {
    final start = pageIndex * pageSize;
    if (start >= _all.length) {
      _rows = const [];
      return;
    }
    final end = (start + pageSize).clamp(0, _all.length);
    _rows = _all.sublist(start, end).map<DataGridRow>(_toRow).toList();
  }

  DataGridRow _toRow(Department d) {
    return DataGridRow(cells: [
      DataGridCell<int>(columnName: 'id', value: d.id),
      DataGridCell<String>(columnName: 'name', value: d.name),
      DataGridCell<String>(
          columnName: 'organization', value: d.organizationName ?? '-'),
      DataGridCell<bool>(columnName: 'status', value: d.isActive),
      // نُبقي الكائن كاملاً ليتمكّن صف الإجراءات من تمريره للدوال.
      DataGridCell<Department>(columnName: 'actions', value: d),
    ]);
  }

  @override
  List<DataGridRow> get rows => _rows;

  /// ترقيم من جهة العميل: نقتطع شريحة الصفحة الجديدة من [_all] ونُخطر الجدول.
  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    _buildPage(newPageIndex);
    notifyListeners();
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
              child: DepartmentStatusBadge(isActive: cell.value as bool),
            );
          case 'actions':
            final department = cell.value as Department;
            final toggling = isToggling(department);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                DepartmentActionButton(
                  icon: Icons.account_tree_outlined,
                  backgroundColor: AppColors.lightPrimary,
                  iconColor: AppColors.primary,
                  tooltip: 'عرض الشعب التابعة',
                  onTap: () => onOpenChildren(department),
                ),
                const SizedBox(width: 6),
                DepartmentActionButton(
                  icon: Icons.visibility_outlined,
                  backgroundColor: AppColors.inputBackground,
                  iconColor: AppColors.secondary,
                  tooltip: 'عرض التفاصيل',
                  onTap: () => onView(department),
                ),
                const SizedBox(width: 6),
                if (toggling)
                  const SizedBox(
                    width: 38,
                    height: 38,
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  DepartmentActionButton(
                    icon: department.isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    backgroundColor: department.isActive
                        ? AppColors.lightPrimary
                        : const Color(0xffFDECEC),
                    iconColor: department.isActive
                        ? AppColors.primary
                        : AppColors.error,
                    tooltip:
                        department.isActive ? 'تعطيل القسم' : 'تفعيل القسم',
                    onTap: () => onToggleStatus(department),
                  ),
              ],
            );
          case 'id':
            return _cell(cell.value.toString(), muted: true);
          case 'name':
            return _cell(cell.value.toString(), bold: true);
          case 'organization':
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
        maxLines: 2,
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
