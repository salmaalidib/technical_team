import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

class AppRouter {
  static const bool devBypassAuth = true;

  static final router = GoRouter(
    initialLocation: '/dashboard',

    redirect: (context, state) {
      if (devBypassAuth) {
        return null;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final sessionId = state.extra as String?;
          if (sessionId == null || sessionId.isEmpty) {
            return const LoginPage();
          }
          return OtpPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
}