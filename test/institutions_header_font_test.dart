import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:technical_team/features/institutions/presentation/bloc/institutions_bloc.dart';
import 'package:technical_team/features/institutions/presentation/bloc/institutions_state.dart';
import 'package:technical_team/features/institutions/presentation/widgets/institutions_header.dart';
import 'package:technical_team/shared/theme/app_theme.dart';

/// bloc وهمي: الترويسة تقرأ `breadcrumb` فقط لاختيار العنوان ونص الزر.
class _FakeBloc extends Cubit<InstitutionsState>
    implements InstitutionsBloc {
  _FakeBloc() : super(const InstitutionsState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('زر «إنشاء مؤسسة جديدة» يعرض خط Cairo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<InstitutionsBloc>.value(
            value: _FakeBloc(),
            child: const Scaffold(body: InstitutionsHeader()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<RichText>(
      find
          .descendant(
            of: find.text('إنشاء مؤسسة جديدة'),
            matching: find.byType(RichText),
          )
          .first,
    );

    String? font;
    label.text.visitChildren((span) {
      if (span is TextSpan && (span.text?.isNotEmpty ?? false)) {
        font = span.style?.fontFamily;
      }
      return true;
    });

    expect(font, 'Cairo');
  });
}
