import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../institutions/presentation/bloc/institutions_bloc.dart';
import '../../../institutions/presentation/bloc/institutions_event.dart';
import '../../../institutions/presentation/widgets/create_institution_dialog.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/theme/app_dimens.dart';

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

  /// Escape hatch for an account that lands here with zero organizations:
  /// creating one from this screen is the only way forward, since `/institutions`
  /// sits behind the dashboard this user cannot reach yet.
  ///
  /// A fresh [InstitutionsBloc] is created for the dialog (the page has none of
  /// its own) and `LoadInstitutions` primes the locations its optional picker
  /// shows. On success the organization list is reloaded so the new institution
  /// appears as a selectable card.
  Future<void> _openCreateInstitution(BuildContext context) async {
    final bloc = getIt<InstitutionsBloc>()..add(const LoadInstitutions());
    try {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.scrim,
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CreateInstitutionDialog(),
        ),
      );
      // The dialog pops itself only after a successful create, but it can also
      // be dismissed — reloading either way costs one request and keeps the
      // list honest.
      await _cubit.load();
    } finally {
      await bloc.close();
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
      return const AppSkeleton.list();
    }

    if (state.status == RequestStatus.failure) {
      return _ErrorState(
        message: state.error ?? 'تعذّر تحميل المؤسسات',
        onRetry: () => _cubit.load(),
      );
    }

    if (state.organizations.isEmpty) {
      return _EmptyState(
        onCreate: () => _openCreateInstitution(context),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
              // سهم دخول في واجهة RTL: يشير نحو اليمين (اتجاه القراءة).
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 16,
                textDirection: TextDirection.rtl,
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
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown when the account resolves to zero organizations. Unlike [_ErrorState]
/// this is not a failure — nothing went wrong, there is simply nothing to pick
/// yet — so it leads with the create action and keeps the reload secondary.
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onRetry;

  const _EmptyState({required this.onCreate, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          'لا توجد مؤسسات متاحة لحسابك',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'ابدأ بإنشاء مؤسسة لتتمكن من الدخول إلى النظام والعمل بها.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text(
              'إنشاء مؤسسة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.inputBackground,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
