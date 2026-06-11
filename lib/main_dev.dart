import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:technical_team/core/di/injection.dart';
import 'package:technical_team/core/error/pointer_hit_test_guard.dart';

import 'package:technical_team/features/auth/di/injection.dart';
import 'package:technical_team/features/departments/di/injection.dart';
import 'package:technical_team/features/employees/di/injection.dart';
import 'package:technical_team/features/fields/di/injection.dart';
import 'package:technical_team/features/institutions/di/injection.dart';
import 'package:technical_team/features/roles/di/injection.dart';
import 'package:technical_team/features/type_processes/di/injection.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installPointerHitTestErrorGuard();

  await dotenv.load(fileName: "env/dev.env");
  await setupCoreInjection();
  await setupAuthInjection();
  await setupInstitutionsInjection();
  await setupDepartmentsInjection();
  await setupRolesInjection();
  await setupTypeProcessesInjection();
  await setupFieldsInjection();
  await setupEmployeesInjection();

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
      routerConfig: AppRouter.router,
    );
  }
}
