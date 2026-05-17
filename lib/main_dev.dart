import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:technical_team/features/auth/di/injection.dart';
import 'package:technical_team/features/dash/presentation/pages/dash_page.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';

import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "env/dev.env");
  await setupLoginInjection();

  runApp(const TechnicalTeamApp());
}

class TechnicalTeamApp extends StatelessWidget {
  const TechnicalTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: dotenv.env['APP_NAME'] ?? 'Technical Team',
      theme: AppTheme.lightTheme,

      home: const LoginPage(),

      routes: {
        "/otp": (context) {
          final sessionId = ModalRoute.of(context)!.settings.arguments as String;

          return OtpPage(sessionId: sessionId);
        },

        "/dashboard": (_) => const DashboardPage(),
      },
    );
  }
}