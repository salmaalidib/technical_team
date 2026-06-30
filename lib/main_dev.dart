import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'package:technical_team/core/di/injection.dart';
import 'package:technical_team/core/error/pointer_hit_test_guard.dart';
import 'package:technical_team/core/services/notification_service.dart';
import 'package:technical_team/core/services/push_socket.dart';
import 'package:technical_team/core/services/tray_service.dart';

import 'package:technical_team/features/auth/di/injection.dart';
import 'package:technical_team/features/departments/di/injection.dart';
import 'package:technical_team/features/employees/di/injection.dart';
import 'package:technical_team/features/fields/di/injection.dart';
import 'package:technical_team/features/institutions/di/injection.dart';
import 'package:technical_team/features/roles/di/injection.dart';
import 'package:technical_team/features/type_processes/di/injection.dart';
import 'package:technical_team/features/type_docs/di/injection.dart';
import 'package:technical_team/features/templates/di/injection.dart';
import 'package:technical_team/features/process_builder/di/injection.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

/// `true` على منصّات سطح المكتب التي ندعم عليها الإشعارات والـ tray.
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installPointerHitTestErrorGuard();

  // تهيئة نافذة سطح المكتب يجب أن تسبق runApp وبعد ensureInitialized مباشرةً.
  // النافذة تُنشأ مخفية ثم تُظهَر داخل waitUntilReadyToShow.
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await dotenv.load(fileName: "env/dev.env");
  await setupCoreInjection();
  await setupAuthInjection();
  await setupInstitutionsInjection();
  await setupDepartmentsInjection();
  await setupRolesInjection();
  await setupTypeProcessesInjection();
  await setupTypeDocsInjection();
  await setupTemplatesInjection();
  await setupFieldsInjection();
  await setupEmployeesInjection();
  await setupProcessBuilderInjection();

  // ترتيب طبقات الإشعارات: (1) تهيئة العرض → (2) شريط النظام واعتراض الإغلاق
  // → (3) فتح اتصال الـ socket. الاتصال يبقى حيًّا في الـ tray عند "إغلاق"
  // النافذة، فتصل الإشعارات حتى وقتها.
  await NotificationService.instance.init(
    onSelect: (payload) {
      // TODO(routing): اربط الـ payload بمنطق التنقّل (go_router) عند الضغط
      // على الإشعار. مثال: فكّ JSON واستخرج المسار ثم AppRouter.router.go(...).
      debugPrint('[Notification] tapped, payload: $payload');
    },
  );
  if (_isDesktop) {
    await TrayService.instance.init();
  }
  // يبدأ الاتصال؛ يعيد المحاولة تلقائيًّا حتى لو لم يكن المستخدم مسجّلًا بعد
  // (سيتصل بدون توكن ثم يُعيد الاتصال بعد تسجيل الدخول عند انقطاعه).
  await getIt<PushSocket>().start();

  runApp(const TechnicalTeamApp());
}

class TechnicalTeamApp extends StatelessWidget {
  const TechnicalTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: dotenv.env['APP_NAME'] ?? 'Technical Team',
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
      // يُركَّب قرب جذر الشجرة فيبقى حيًّا طوال الجلسة: يعترض زر الإغلاق
      // (إخفاء إلى الـ tray) ويدير قائمة شريط النظام. عند الخروج النهائي يُغلق
      // اتصال الـ socket أولًا. على غير سطح المكتب يمرّر child كما هو.
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        if (!_isDesktop) return app;
        return TrayBootstrap(
          onBeforeExit: () => getIt<PushSocket>().dispose(),
          child: app,
        );
      },
    );
  }
}
