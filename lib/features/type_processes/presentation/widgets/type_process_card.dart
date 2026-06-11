import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/type_process.dart';
import '../bloc/type_processes_bloc.dart';
import '../bloc/type_processes_event.dart';

class TypeProcessCard extends StatelessWidget {
  final TypeProcess typeProcess;
  final bool toggling;

  const TypeProcessCard({
    super.key,
    required this.typeProcess,
    this.toggling = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: typeProcess.isActive ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(typeProcess: typeProcess, toggling: toggling),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _StatusRow(isActive: typeProcess.isActive),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final TypeProcess typeProcess;
  final bool toggling;

  const _TopRow({required this.typeProcess, required this.toggling});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.category_outlined,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeProcess.name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${typeProcess.id}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.tag_rounded,
                        size: 15, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        _StatusToggle(typeProcess: typeProcess, toggling: toggling),
      ],
    );
  }
}

/// Active / inactive toggle — the only edit the backend exposes for a process
/// type (`PUT /api/typeProcess/{id}` with `{ is_active }`).
class _StatusToggle extends StatelessWidget {
  final TypeProcess typeProcess;
  final bool toggling;

  const _StatusToggle({required this.typeProcess, required this.toggling});

  @override
  Widget build(BuildContext context) {
    if (toggling) {
      return const SizedBox(
        width: 46,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Switch.adaptive(
      value: typeProcess.isActive,
      activeColor: AppColors.primary,
      onChanged: (value) => context.read<TypeProcessesBloc>().add(
            ToggleTypeProcessStatus(id: typeProcess.id, isActive: value),
          ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isActive;

  const _StatusRow({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'مفعّل' : 'غير مفعّل',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
