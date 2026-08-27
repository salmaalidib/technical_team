import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/shared/theme/app_theme.dart';
import 'package:technical_team/shared/widgets/app_snackbar.dart';

/// يتحقق أن كل نص في التطبيق يرث خط Cairo فعلياً بعد بناء الشجرة.
void main() {
  /// يجمع كل مقاطع النص المعروضة ويعيد أسماء الخطوط الفعلية المستخدمة.
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
    // MaterialIcons خط الأيقونات وليس نصاً — يُستثنى من الفحص.
    fonts.remove('MaterialIcons');
    return fonts;
  }

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      );

  testWidgets('نص عادي يرث Cairo من الثيم', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: Text('مرحبا'))));
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('نص داخل TextStyle مخصص (بدون fontFamily) يبقى Cairo',
      (tester) async {
    await tester.pumpWidget(host(
      const Scaffold(
        body: Text('مرحبا',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
    ));
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('الأزرار ترث Cairo', (tester) async {
    await tester.pumpWidget(host(
      Scaffold(
          body: ElevatedButton(onPressed: () {}, child: const Text('حفظ'))),
    ));
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('الحوار (Dialog) يرث Cairo', (tester) async {
    await tester.pumpWidget(host(
      Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showDialog(
              context: ctx,
              builder: (_) => const AlertDialog(
                title: Text('تأكيد'),
                content: Text('هل أنت متأكد؟'),
              ),
            ),
            child: const Text('افتح'),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('SnackBar يرث Cairo', (tester) async {
    await tester.pumpWidget(host(
      Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => AppSnackBar.show(ctx, message: 'تم الحفظ'),
            child: const Text('اعرض'),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(renderedFonts(tester), {'Cairo'});
  });

  testWidgets('حقل الإدخال (hint + نص) يرث Cairo', (tester) async {
    await tester.pumpWidget(host(
      const Scaffold(
        body: TextField(decoration: InputDecoration(hintText: 'ابحث...')),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'قيمة');
    await tester.pump();
    expect(renderedFonts(tester), {'Cairo'});
  });
}
