import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/type_processes_bloc.dart';
import '../bloc/type_processes_event.dart';
import '../bloc/type_processes_state.dart';
import '../widgets/type_process_card.dart';
import '../widgets/type_processes_header.dart';

class TypeProcessesPage extends StatelessWidget {
  const TypeProcessesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TypeProcessesBloc>()..add(const LoadTypeProcesses()),
      child: BlocListener<TypeProcessesBloc, TypeProcessesState>(
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
        child: const _TypeProcessesView(),
      ),
    );
  }
}

class _TypeProcessesView extends StatelessWidget {
  const _TypeProcessesView();

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
            TypeProcessesHeader(),
            SizedBox(height: 28),
            _TypeProcessesBody(),
          ],
        ),
      ),
    );
  }
}

class _TypeProcessesBody extends StatelessWidget {
  const _TypeProcessesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TypeProcessesBloc, TypeProcessesState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.typeProcesses != c.typeProcesses ||
          p.togglingIds != c.togglingIds,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<TypeProcessesBloc>().add(const LoadTypeProcesses()),
            );
          case RequestStatus.success:
            if (state.typeProcesses.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'لا توجد أنواع عمليات لعرضها',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              );
            }
            return _TypeProcessesGrid(state: state);
        }
      },
    );
  }
}

/// Responsive card grid: three columns on desktop, two on tablet, one on
/// mobile.
class _TypeProcessesGrid extends StatelessWidget {
  final TypeProcessesState state;

  const _TypeProcessesGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
        final cardWidth = (width - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          textDirection: TextDirection.rtl,
          children: [
            for (final type in state.typeProcesses)
              SizedBox(
                width: cardWidth,
                child: TypeProcessCard(
                  key: ValueKey(type.id),
                  typeProcess: type,
                  toggling: state.togglingIds.contains(type.id),
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
