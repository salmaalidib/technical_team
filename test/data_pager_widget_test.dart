import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:technical_team/shared/theme/app_theme.dart';
import 'package:technical_team/shared/widgets/table/data_pager_widget.dart';

class _Src extends DataGridSource {
  @override
  List<DataGridRow> get rows => const [];
  @override
  DataGridRowAdapter buildRow(DataGridRow row) =>
      DataGridRowAdapter(cells: const [SizedBox.shrink()]);
}

void main() {
  Widget host({
    required int page,
    required int pageSize,
    required int total,
    ValueChanged<int>? onPage,
    ValueChanged<int>? onSize,
  }) =>
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: DataPagerWidget(
              dataSource: _Src(),
              pageNumber: page,
              pageSize: pageSize,
              total: total,
              onPageChanged: onPage ?? (_) {},
              onPageSizeChanged: onSize ?? (_) {},
            ),
          ),
        ),
      );

  testWidgets('يختفي الشريط عندما لا توجد بيانات', (tester) async {
    await tester.pumpWidget(host(page: 1, pageSize: 10, total: 0));
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('يعرض نطاق الصفوف بالعربية', (tester) async {
    await tester.pumpWidget(host(page: 1, pageSize: 10, total: 34));
    expect(find.text('عرض 1–10 من 34'), findsOneWidget);
    expect(find.text('صفوف لكل صفحة'), findsOneWidget);
  });

  testWidgets('النطاق يُقصّ عند الصفحة الأخيرة', (tester) async {
    await tester.pumpWidget(host(page: 4, pageSize: 10, total: 34));
    expect(find.text('عرض 31–34 من 34'), findsOneWidget);
  });

  testWidgets('يعرض كل الصفحات دون اختصار عندما تكون ≤ 7', (tester) async {
    await tester.pumpWidget(host(page: 1, pageSize: 10, total: 40));
    for (final p in ['1', '2', '3', '4']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.text('…'), findsNothing);
  });

  testWidgets('يختصر بـ … عندما تكثر الصفحات', (tester) async {
    // 200 عنصر / 10 = 20 صفحة، والصفحة الحالية في المنتصف.
    await tester.pumpWidget(host(page: 10, pageSize: 10, total: 200));
    expect(find.text('…'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('10'), findsWidgets); // الصفحة الحالية
  });

  testWidgets('الضغط على رقم صفحة يُبلّغ الصفحة الجديدة', (tester) async {
    int? picked;
    await tester.pumpWidget(
        host(page: 1, pageSize: 10, total: 40, onPage: (p) => picked = p));
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(picked, 3);
  });

  testWidgets('سهم التالي/السابق يعمل ويتعطّل عند الطرفين', (tester) async {
    int? picked;
    await tester.pumpWidget(
        host(page: 1, pageSize: 10, total: 40, onPage: (p) => picked = p));

    // في الصفحة الأولى: "السابق" معطّل فلا يُبلّغ شيئاً.
    await tester.tap(find.byTooltip('الصفحة السابقة'));
    await tester.pump();
    expect(picked, isNull);

    await tester.tap(find.byTooltip('الصفحة التالية'));
    await tester.pump();
    expect(picked, 2);
  });

  testWidgets('تغيير عدد الصفوف يُبلّغ الحجم الجديد', (tester) async {
    int? size;
    await tester.pumpWidget(
        host(page: 1, pageSize: 10, total: 40, onSize: (s) => size = s));
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50').last);
    await tester.pumpAndSettle();
    expect(size, 50);
  });

  testWidgets('رقم عدد الصفوف يظهر كاملاً دون قصّ', (tester) async {
    await tester.pumpWidget(host(page: 1, pageSize: 20, total: 40));
    await tester.pumpAndSettle();

    // نص القيمة المختارة داخل الحاوية.
    final textFinder = find.text('20').first;
    final textSize = tester.getSize(textFinder);

    // الحاوية التي ترسم الخلفية حول المنتقي.
    final boxFinder = find
        .ancestor(of: textFinder, matching: find.byType(Container))
        .first;
    final boxSize = tester.getSize(boxFinder);

    // الصندوق يجب أن يستوعب النص كاملاً (ارتفاعاً) وإلا حدث قصّ.
    expect(boxSize.height, greaterThanOrEqualTo(textSize.height),
        reason: 'ارتفاع الحاوية أصغر من النص ⇒ قصّ');
    expect(boxSize.height, greaterThanOrEqualTo(36));
  });
}
