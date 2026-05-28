import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:technical_team/core/di/injection.dart';

import 'package:technical_team/features/auth/di/injection.dart';
import 'package:technical_team/features/dashboard/presentation/pages/dashboard_page.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "env/dev.env");
  await setupCoreInjection();
  await setupAuthInjection();

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
