import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/roles_bloc.dart';
import '../bloc/roles_event.dart';
import '../bloc/roles_state.dart';
import '../widgets/role_card.dart';
import '../widgets/roles_header.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RolesBloc>()..add(const LoadRoles()),
      child: BlocListener<RolesBloc, RolesState>(
        listenWhen: (p, c) => p.actionError != c.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            AppSnackBar.show(
              context,
              message: state.actionError!,
              isError: true,
            );
          }
        },
        child: const _RolesView(),
      ),
    );
  }
}

class _RolesView extends StatelessWidget {
  const _RolesView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    return Container(
      color: const Color(0xffF0EFE7),
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RolesHeader(),
            SizedBox(height: 28),
            _RolesBody(),
          ],
        ),
      ),
    );
  }
}

class _RolesBody extends StatelessWidget {
  const _RolesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesBloc, RolesState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.roles != c.roles ||
          p.togglingIds != c.togglingIds,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const AppSkeleton.cards();
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () => context.read<RolesBloc>().add(const LoadRoles()),
            );
          case RequestStatus.success:
            if (state.roles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'لا توجد أدوار لعرضها',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              );
            }
            return _RolesGrid(state: state);
        }
      },
    );
  }
}

/// Responsive card grid: two columns on tablet/desktop (matching the design),
/// a single column on mobile.
class _RolesGrid extends StatelessWidget {
  final RolesState state;

  const _RolesGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          textDirection: TextDirection.rtl,
          children: [
            for (final role in state.roles)
              SizedBox(
                width: cardWidth,
                child: RoleCard(
                  key: ValueKey(role.id),
                  role: role,
                  toggling: state.togglingIds.contains(role.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
