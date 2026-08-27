import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:technical_team/features/roles/presentation/bloc/roles_bloc.dart';
import 'package:technical_team/features/roles/presentation/bloc/roles_state.dart';
import 'package:technical_team/features/roles/presentation/widgets/roles_header.dart';
import 'package:technical_team/shared/theme/app_theme.dart';

class _FakeBloc extends Cubit<RolesState> implements RolesBloc {
  _FakeBloc() : super(const RolesState());
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  // الاختبارات تعمل بخط بديل أعرض من Cairo فيفيض الزر ذو العرض الثابت.
  // نحمّل الخط الحقيقي كي تعكس القياسات ما يراه المستخدم.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Cairo');
    for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      final f = File('assets/fonts/Cairo-$w.ttf');
      if (f.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await loader.load();
  });

  testWidgets('عنوان «إدارة الأدوار» وأيقونته يبدآن من أقصى اليمين',
      (tester) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<RolesBloc>.value(
          value: _FakeBloc(),
          child: const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [RolesHeader()],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final header = tester.getRect(find.byType(RolesHeader));
    final icon = tester.getRect(find.byIcon(Icons.shield_outlined));

    // الأيقونة أول عنصر في صفّ العنوان (RTL) ⇒ يجب أن تلامس الحافة اليمنى.
    expect(icon.right, closeTo(header.right, 1.0),
        reason: 'صفّ العنوان لا يبدأ من اليمين');
  });

  testWidgets('زر «إنشاء دور جديد» بأبعاد 210×54', (tester) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<RolesBloc>.value(
          value: _FakeBloc(),
          child: const Scaffold(body: RolesHeader()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final btn = tester.getSize(find.byType(ElevatedButton));
    expect(btn.width, 210);
    expect(btn.height, 54);
  });
}
