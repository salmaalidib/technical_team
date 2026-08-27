import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:technical_team/shared/theme/app_text_styles.dart';
import 'package:technical_team/shared/theme/app_theme.dart';
import 'package:technical_team/shared/widgets/table/grid_column.dart';

/// مصدر بيانات يحاكي خلايا التطبيق: النمط يثبّت `fontFamily` صراحةً،
/// لأن Syncfusion يفرض `DefaultTextStyle` خاصاً به فلا يصل خط الثيم.
class _Src extends DataGridSource {
  _Src({required this.pinFont});

  final bool pinFont;

  @override
  List<DataGridRow> get rows => [
        const DataGridRow(
          cells: [DataGridCell<String>(columnName: 'name', value: 'v')],
        ),
      ];

  @override
  DataGridRowAdapter buildRow(DataGridRow row) => DataGridRowAdapter(
        cells: [
          Text(
            'مديرية التربية',
            style: TextStyle(
              fontFamily: pinFont ? AppTextStyles.fontFamily : null,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

void main() {
  Set<String?> renderedFonts(WidgetTester tester) {
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
    return fonts;
  }

  Widget grid({required bool pinFont}) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SfDataGridTheme(
              data: const SfDataGridThemeData(),
              child: SfDataGrid(
                source: _Src(pinFont: pinFont),
                columns: [
                  buildGridColumn(columnName: 'name', label: 'اسم المؤسسة'),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('خلايا ورؤوس SfDataGrid تعرض Cairo', (tester) async {
    await tester.pumpWidget(grid(pinFont: true));
    await tester.pumpAndSettle();
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('إثبات الحاجة: خلية بلا fontFamily تسقط لخط النظام',
      (tester) async {
    await tester.pumpWidget(grid(pinFont: false));
    await tester.pumpAndSettle();
    // الرأس يبقى Cairo (buildGridColumn يثبّته)، أما الخلية فتسقط.
    expect(renderedFonts(tester).contains('Cairo'), isTrue);
    expect(renderedFonts(tester).length, greaterThan(1));
  });
}
