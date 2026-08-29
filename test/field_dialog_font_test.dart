import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:technical_team/features/fields/domain/entities/field_type.dart';
import 'package:technical_team/features/fields/presentation/bloc/fields_bloc.dart';
import 'package:technical_team/features/fields/presentation/bloc/fields_state.dart';
import 'package:technical_team/features/fields/presentation/widgets/field_type_card.dart';
import 'package:technical_team/features/fields/presentation/widgets/options_form.dart';
import 'package:technical_team/shared/theme/app_theme.dart';

class _FakeFieldsBloc extends Cubit<FieldsState> implements FieldsBloc {
  _FakeFieldsBloc() : super(const FieldsState());
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

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

  /// الخط الفعلي لكل مقطع: المقطع بلا style يرث خط الجذر، لذا نمرّر خط
  /// الأب إلى الأبناء تماماً كما يفعل محرّك الرسم.
  Map<String, String?> fonts(WidgetTester tester) {
    final out = <String, String?>{};
    void walk(InlineSpan span, String? inherited) {
      final own = span is TextSpan ? span.style?.fontFamily : null;
      final eff = own ?? inherited;
      if (span is TextSpan) {
        if (span.text?.isNotEmpty ?? false) out[span.text!] = eff;
        for (final c in span.children ?? const <InlineSpan>[]) {
          walk(c, eff);
        }
      }
    }

    for (final el in find.byType(RichText).evaluate()) {
      walk((el.widget as RichText).text, null);
    }
    return out;
  }

  testWidgets('كل نصوص حوار «إنشاء اختيار واحد» بخط Cairo', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<FieldsBloc>.value(
          value: _FakeFieldsBloc(),
          child: Scaffold(
            body: OptionsForm(
              type: FieldType.radioGroup,
              meta: kFieldTypeMeta[FieldType.radioGroup]!,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final rendered = fonts(tester);
    expect(rendered, isNotEmpty);

    rendered.forEach((text, font) {
      if (font == 'MaterialIcons') return;
      expect(font, 'Cairo', reason: 'النص "$text" لا يستخدم Cairo');
    });
  });
}
