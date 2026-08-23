import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/institution.dart';
import 'institution_action_button.dart';

/// مصدر بيانات جدول المؤسسات لـ [SfDataGrid].
///
/// الترقيم هنا من جهة العميل: يحتفظ المصدر بكامل قائمة المستوى الحالي ويقتطع
/// شريحة الصفحة المطلوبة داخلياً في [handlePageChange]، تماشياً مع منطق
/// الـ pager. تُمرَّر دوال الإجراءات (المؤسسات التابعة) من الجدول.
class InstitutionsDataSource extends DataGridSource {
  InstitutionsDataSource({
    required List<Institution> institutions,
    required this.pageSize,
    required this.onOpenChildren,
  }) {
    _all = institutions;
    _buildPage(0);
  }

  final void Function(Institution institution) onOpenChildren;

  int pageSize;
  List<Institution> _all = [];
  List<DataGridRow> _rows = [];

  /// يعيد بناء بيانات المصدر (عند تغيّر المستوى أو البحث) ويعود للصفحة الأولى.
  void updateData(List<Institution> institutions, {int? pageSize}) {
    _all = institutions;
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

  DataGridRow _toRow(Institution i) {
    return DataGridRow(cells: [
      DataGridCell<int>(columnName: 'id', value: i.id),
      DataGridCell<String>(columnName: 'name', value: i.name),
      DataGridCell<String>(columnName: 'parent', value: i.parentName ?? '-'),
      DataGridCell<String>(
          columnName: 'location', value: i.locationName ?? '-'),
      // نُبقي الكائن كاملاً ليتمكّن صف الإجراءات من تمريره للدوال.
      DataGridCell<Institution>(columnName: 'actions', value: i),
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
          case 'actions':
            final institution = cell.value as Institution;
            // الزر يظهر دائماً — حتى لو لم يكن للمؤسسة أبناء بعد — كي يمكن
            // الدخول إليها وإنشاء أول مؤسسة تابعة من الداخل.
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                InstitutionActionButton(
                  icon: Icons.account_tree_outlined,
                  backgroundColor: AppColors.lightPrimary,
                  iconColor: AppColors.primary,
                  tooltip: 'عرض المؤسسات التابعة',
                  onTap: () => onOpenChildren(institution),
                ),
              ],
            );
          case 'id':
            return _cell(cell.value.toString(), muted: true);
          case 'name':
            return _cell(cell.value.toString(), bold: true);
          case 'parent':
          case 'location':
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
          fontSize: 14,
          height: 1.4,
          color: muted ? AppColors.textSecondary : AppColors.textPrimary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
