import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:technical_team/features/employees/presentation/widgets/employee_status_badge.dart';
import 'package:technical_team/shared/theme/app_theme.dart';
import 'package:technical_team/shared/widgets/table/grid_column.dart';

/// شارة الحالة تُبنى داخل خلية الجدول وتعتمد على `textTheme` — نتأكد أنها
/// تصل إلى Cairo رغم أن Syncfusion يفرض سياق نص خاصاً به.
class _Src extends DataGridSource {
  @override
  List<DataGridRow> get rows => [
        const DataGridRow(
          cells: [DataGridCell<String>(columnName: 'status', value: 'v')],
        ),
      ];

  @override
  DataGridRowAdapter buildRow(DataGridRow row) => DataGridRowAdapter(
        cells: [const EmployeeStatusBadge(isActive: true)],
      );
}

void main() {
  testWidgets('شارة الحالة داخل الجدول تعرض Cairo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SfDataGridTheme(
            data: const SfDataGridThemeData(),
            child: SfDataGrid(
              source: _Src(),
              columns: [
                buildGridColumn(columnName: 'status', label: 'الحالة'),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final fonts = <String?>{};
    for (final el in find.byType(RichText).evaluate()) {
      final rt = el.widget as RichText;
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text?.isNotEmpty ?? false)) {
          fonts.add(span.style?.fontFamily);
        }
        return true;
      });
    }
    fonts.remove('MaterialIcons');
    expect(fonts, {'Cairo'});
  });
}
