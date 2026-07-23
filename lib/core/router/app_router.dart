import 'package:go_router/go_router.dart';
import 'package:technical_team/features/departments/presentation/pages/departments_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/institutions/presentation/pages/institutions_page.dart';
import '../../features/roles/presentation/pages/roles_page.dart';
import '../../features/type_processes/presentation/pages/type_processes_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/select_organization/presentation/pages/select_organization_page.dart';
import '../../shared/layouts/app_shell.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/process_builder/presentation/pages/process_types_page.dart';
import '../../features/process_builder/presentation/pages/process_by_type_page.dart';
import '../../features/process_builder/presentation/pages/process_details_page.dart';
import '../../features/process_builder/presentation/pages/admin_review_page.dart';
import '../../features/process_builder/presentation/widgets/create_process_wizard.dart';
import '../../features/templates/presentation/pages/templates_page.dart';
import '../../features/settings/presentation/pages/sett_page.dart' as settings;
import '../../features/app_update/presentation/pages/force_update_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routerNeglect: true,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
      // خارج الـ ShellRoute عمداً: تُعرض قبل تسجيل الدخول وبلا أي chrome
      // (لا AppShell) — التحديث الإجباري يسبق كل شيء آخر.
      GoRoute(
        path: '/force-update',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ForceUpdatePage(),
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
      // Standalone (no app shell): the user picks their active organization
      // once after login before entering the dashboard.
      GoRoute(
        path: '/select-organization',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SelectOrganizationPage(),
        ),
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
            path: '/type-processes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TypeProcessesPage(),
            ),
          ),
          GoRoute(
            path: '/employees',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmployeesPage(),
            ),
          ),
          GoRoute(
            path: '/templates',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TemplatesPage(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProcessTypesPage(),
            ),
          ),
          GoRoute(
            path: '/transactions/admin',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminReviewPage(),
            ),
          ),
          GoRoute(
            path: '/transactions/create',
            pageBuilder: (context, state) {
              final extra = state.extra;
              final typeId = extra is Map ? extra['typeId'] as int? : null;
              final typeName = extra is Map ? extra['typeName'] as String? : null;
              final existingProcessId =
                  extra is Map ? extra['existingProcessId'] as int? : null;
              return NoTransitionPage(
                child: CreateProcessPage(
                  typeId: typeId,
                  typeName: typeName,
                  existingProcessId: existingProcessId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/transactions/type/:typeId',
            // A non-numeric typeId is a malformed link: redirect to the types
            // grid instead of rendering a page under a wrong URL.
            redirect: (context, state) =>
                int.tryParse(state.pathParameters['typeId'] ?? '') == null
                    ? '/transactions'
                    : null,
            pageBuilder: (context, state) {
              final typeId = int.parse(state.pathParameters['typeId']!);
              return NoTransitionPage(
                child: ProcessByTypePage(
                  typeId: typeId,
                  typeName: state.extra as String?,
                ),
              );
            },
          ),
          // NOTE: keep this dynamic ':id' route LAST among the /transactions/*
          // branches. go_router matches in declaration order and stops on the
          // first hit, so any static child added after this (e.g.
          // /transactions/archive) would be swallowed as an ':id'.
          GoRoute(
            path: '/transactions/:id',
            // A non-numeric id is a malformed link: redirect to the types grid
            // instead of rendering details under a wrong URL.
            redirect: (context, state) =>
                int.tryParse(state.pathParameters['id'] ?? '') == null
                    ? '/transactions'
                    : null,
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: ProcessDetailsPage(id: id),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: settings.DashboardPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
