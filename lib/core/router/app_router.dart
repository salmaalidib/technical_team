import 'package:go_router/go_router.dart';
import 'package:technical_team/features/departments/presentation/pages/departments_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/fields/presentation/pages/fields_page.dart';
import '../../features/institutions/presentation/pages/institutions_page.dart';
import '../../features/roles/presentation/pages/roles_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/layouts/app_shell.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/dashboard',
    routerNeglect: true,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final sessionId = state.extra as String?;
          if (sessionId == null || sessionId.isEmpty) {
            return const NoTransitionPage(child: LoginPage());
          }

          return NoTransitionPage(
            child: OtpPage(sessionId: sessionId),
          );
        },
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
            child: AppShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/institutions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InstitutionsPage(),
            ),
          ),
          GoRoute(
            path: '/departments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DepartmentsPage(),
            ),
          ),
          GoRoute(
            path: '/roles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RolesPage(),
            ),
          ),
          GoRoute(
            path: '/fields',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FieldsPage(),
            ),
          ),
          GoRoute(
            path: '/employees',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmployeesPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
