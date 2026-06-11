import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import '../bloc/fields_state.dart';
import '../widgets/create_field_dialog.dart';
import '../widgets/field_instances_section.dart';
import '../widgets/field_type_grid.dart';
import '../widgets/fields_header.dart';

class FieldsPage extends StatelessWidget {
  const FieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FieldsBloc>()..add(const LoadAllFields()),
      child: const _FieldsView(),
    );
  }
}

class _FieldsView extends StatelessWidget {
  const _FieldsView();

  void _openCreateDialog(BuildContext context, FieldType type) {
    final bloc = context.read<FieldsBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateFieldDialog(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return Container(
      color: const Color(0xffF0EFE7),
      child: BlocBuilder<FieldsBloc, FieldsState>(
        buildWhen: (p, c) => p.loadStatus != c.loadStatus,
        builder: (context, state) {
          final isLoading = state.loadStatus == RequestStatus.loading ||
              state.loadStatus == RequestStatus.initial;
          final isFailure = state.loadStatus == RequestStatus.failure;

          // While loading / on error: keep the header but center the loader
          // (or error) in the remaining space — never show a half-built grid.
          if (isLoading || isFailure) {
            return Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldsHeader(),
                  Expanded(
                    child: Center(
                      child: isLoading
                          ? const _Loading()
                          : _Error(
                              message: state.error ?? 'حدث خطأ غير متوقع',
                              onRetry: () => context
                                  .read<FieldsBloc>()
                                  .add(const LoadAllFields()),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldsHeader(),
                const SizedBox(height: 28),
                const FieldTypeGrid(),
                const SizedBox(height: 24),
                BlocBuilder<FieldsBloc, FieldsState>(
                  buildWhen: (p, c) => p.selectedType != c.selectedType,
                  builder: (context, state) => FieldInstancesSection(
                    onAdd: () =>
                        _openCreateDialog(context, state.selectedType),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'جارٍ تحميل الحقول...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
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
