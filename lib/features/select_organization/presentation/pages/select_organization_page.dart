import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';

/// Shown once right after login. The user picks the organization they'll work
/// in; the choice is persisted by [ActiveOrganizationCubit] and reused across
/// every feature, so no form ever asks for the organization again.
///
/// This screen only SELECTS an existing organization — creating/managing
/// organizations stays on the dedicated `/institutions` page.
class SelectOrganizationPage extends StatefulWidget {
  const SelectOrganizationPage({super.key});

  @override
  State<SelectOrganizationPage> createState() => _SelectOrganizationPageState();
}

class _SelectOrganizationPageState extends State<SelectOrganizationPage> {
  late final ActiveOrganizationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ActiveOrganizationCubit>();
    // The splash usually warms the list already; reload only if it's empty so
    // arriving here straight after login (no prior load) still shows options.
    if (_cubit.state.organizations.isEmpty) {
      _cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocProvider.value(
          value: _cubit,
          child: BlocBuilder<ActiveOrganizationCubit, ActiveOrgState>(
            builder: (context, state) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _body(context, state),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ActiveOrgState state) {
    if (state.status == RequestStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == RequestStatus.failure) {
      return _ErrorState(
        message: state.error ?? 'تعذّر تحميل المؤسسات',
        onRetry: () => _cubit.load(),
      );
    }

    if (state.organizations.isEmpty) {
      return _ErrorState(
        message: 'لا توجد مؤسسات متاحة لحسابك',
        onRetry: () => _cubit.load(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 28),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: state.organizations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final org = state.organizations[i];
              return _OrgCard(
                name: org.name,
                subtitle: org.parentName,
                onTap: () async {
                  await _cubit.setActive(org);
                  if (context.mounted) context.go('/dashboard');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.lightPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: AppColors.primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'اختر المؤسسة',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'اختر المؤسسة التي ستعمل بها. يمكنك تغييرها لاحقاً.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _OrgCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final VoidCallback onTap;

  const _OrgCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 56),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
