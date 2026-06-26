import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/theme/app_colors.dart';

/// Entry screen. Decides where to send the user based on whether a saved
/// access token exists and whether an active organization is already chosen:
///   * no token                       → /login
///   * token + active org persisted   → /dashboard
///   * token but no active org        → /select-organization
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decideStartDestination();
  }

  Future<void> _decideStartDestination() async {
    String? token;
    try {
      final storage = getIt<SecureStorageService>();
      // A tiny delay so the splash is actually visible on a fast start.
      final results = await Future.wait([
        storage.getToken(),
        Future<void>.delayed(const Duration(milliseconds: 600)),
      ]);
      token = results.first as String?;
    } catch (_) {
      // Storage unavailable (e.g. on web before setup) → treat as logged out
      // instead of hanging on the splash.
      token = null;
    }

    final hasToken = token != null && token.isNotEmpty;
    if (!hasToken) {
      if (mounted) context.go('/login');
      return;
    }

    // Logged in: warm the organization list (so feature pages never fetch it)
    // and resolve the persisted selection. A load failure or a missing/stale
    // selection sends the user to pick one, rather than hanging or landing on
    // a dashboard whose forms can't submit.
    final activeOrg = getIt<ActiveOrganizationCubit>();
    try {
      await activeOrg.load();
    } catch (_) {
      // Treated as "no active org" below.
    }

    if (!mounted) return;
    context.go(activeOrg.hasActiveOrg ? '/dashboard' : '/select-organization');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'الفريق التقني',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
