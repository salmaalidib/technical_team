import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/features/audit_logs/domain/entities/audit_log_actor.dart';
import 'package:technical_team/features/audit_logs/domain/entities/audit_log_entry.dart';
import 'package:technical_team/features/audit_logs/presentation/widgets/audit_log_details_dialog.dart';
import 'package:technical_team/features/audit_logs/presentation/widgets/audit_logs_table.dart';
import 'package:technical_team/shared/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Cairo');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final f = File('assets/fonts/Cairo-$w.ttf');
      if (f.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await loader.load();
  });

  /// يعيد خط كل مقطع نصّي مع نصّه، لتمييز العربي عن الأكواد التقنية.
  Map<String, String?> renderedFonts(WidgetTester tester) {
    final out = <String, String?>{};
    for (final el in find.byType(RichText).evaluate()) {
      final rt = el.widget as RichText;
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text?.isNotEmpty ?? false)) {
          out[span.text!] = span.style?.fontFamily;
        }
        return true;
      });
    }
    return out;
  }

  testWidgets('نصوص سجلّ التدقيق العربية تعرض Cairo', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AuditLogsTable(items: [
            AuditLogEntry(
              id: 1,
              action: 'USER_LOGIN',
              status: AuditLogStatus.success,
              createdAt: DateTime(2026, 1, 1, 10, 30),
              user: const AuditLogActor(
                id: 7,
                userName: 'ahmad',
                firstName: 'أحمد',
                lastName: 'محمود',
              ),
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final fonts = renderedFonts(tester);
    expect(fonts, isNotEmpty);

    fonts.forEach((text, font) {
      if (font == 'MaterialIcons') return;
      // الأكواد التقنية (LTR) تبقى monospace عمداً.
      if (text == 'USER_LOGIN') {
        expect(font, 'monospace', reason: 'كود الإجراء يجب أن يبقى monospace');
        return;
      }
      expect(font, 'Cairo', reason: 'النص "$text" لا يستخدم Cairo');
    });
  });

  testWidgets('حوار تفاصيل السجلّ يعرض Cairo (عدا الأكواد وJSON)',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AuditLogDetailsDialog(
            entry: AuditLogEntry(
              id: 1,
              action: 'USER_LOGIN',
              status: AuditLogStatus.success,
              ipAddress: '10.0.0.5',
              createdAt: DateTime(2026, 1, 1, 10, 30),
              details: const {'ok': true},
              user: const AuditLogActor(
                id: 7,
                userName: 'ahmad',
                firstName: 'أحمد',
                lastName: 'محمود',
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final fonts = renderedFonts(tester);
    expect(fonts, isNotEmpty);

    fonts.forEach((text, font) {
      if (font == 'MaterialIcons' || font == 'monospace') return;
      expect(font, 'Cairo', reason: 'النص "$text" لا يستخدم Cairo');
    });
  });
}
