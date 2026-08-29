import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/features/roles/domain/entities/role_catalog_item.dart';
import 'package:technical_team/features/roles/presentation/widgets/searchable_role_dropdown.dart';

const _roles = [
  RoleCatalogItem(id: 2, name: 'مدير المحاسبة', code: 'ACCOUNTING_MANAGER'),
  RoleCatalogItem(id: 4, name: 'موظف معاملات', code: 'TRANSACTION_CLERK'),
  RoleCatalogItem(id: 5, name: 'مدير الموارد', code: 'HR_MANAGER'),
];

Future<void> pump(WidgetTester tester, {int? value}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: SearchableRoleDropdown(
            roles: _roles,
            value: value,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('shows the hint, and the role NAME once picked — never the code',
      (tester) async {
    await pump(tester);
    expect(find.text('اختر الدور...'), findsOneWidget);

    await pump(tester, value: 2);
    expect(find.text('مدير المحاسبة'), findsOneWidget);
    // الكود لا يظهر في الواجهة إطلاقاً.
    expect(find.textContaining('ACCOUNTING_MANAGER'), findsNothing);
  });

  testWidgets('opening reveals a search box and every role by name only',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.text('ابحث عن دور...'), findsOneWidget);
    for (final r in _roles) {
      expect(find.text(r.name), findsOneWidget);
      expect(find.textContaining(r.code), findsNothing);
    }
  });

  testWidgets('search filters by Arabic name', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'مدير');
    await tester.pumpAndSettle();

    expect(find.text('مدير المحاسبة'), findsOneWidget);
    expect(find.text('مدير الموارد'), findsOneWidget);
    expect(find.text('موظف معاملات'), findsNothing);
  });

  testWidgets('search still matches the hidden code', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'transaction');
    await tester.pumpAndSettle();

    expect(find.text('موظف معاملات'), findsOneWidget);
    expect(find.text('مدير المحاسبة'), findsNothing);
  });

  testWidgets('no match shows the empty state', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ززز');
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
  });

  testWidgets('picking a role reports its id and closes the panel',
      (tester) async {
    int? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: SearchableRoleDropdown(
              roles: _roles,
              value: null,
              onChanged: (v) => picked = v,
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('مدير الموارد'));
    await tester.pumpAndSettle();

    expect(picked, 5);
    expect(find.text('ابحث عن دور...'), findsNothing);
  });
}
