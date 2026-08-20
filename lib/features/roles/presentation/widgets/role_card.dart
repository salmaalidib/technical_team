import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/role_assignment.dart';
import '../bloc/roles_bloc.dart';
import '../bloc/roles_event.dart';
import 'edit_role_permissions_dialog.dart';
import '../../../../shared/theme/app_dimens.dart';

class RoleCard extends StatelessWidget {
  final RoleAssignment role;
  final bool toggling;

  const RoleCard({super.key, required this.role, this.toggling = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: role.isActive ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowFaint,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(role: role, toggling: toggling),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _InfoField(label: 'المؤسسة', value: role.organizationName ?? '—'),
            const SizedBox(height: 14),
            _InfoField(label: 'القسم', value: role.departmentName ?? '—'),
            const SizedBox(height: 14),
            _InfoField(
              label: 'مفتاح Camunda',
              value: role.camundaGroupKey ?? '—',
              monospace: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final RoleAssignment role;
  final bool toggling;

  const _TopRow({required this.role, required this.toggling});

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
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child:
              const Icon(Icons.shield_outlined, color: AppColors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.roleName,
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
                      role.roleCode,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.code_rounded,
                        size: 15, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        _EditPermissionsButton(role: role),
        _StatusToggle(role: role, toggling: toggling),
      ],
    );
  }
}

/// Opens the edit-permissions dialog, reusing the card's [RolesBloc] so the
/// dialog and the list share one state.
///
/// Hidden for global roles (no organization/department, e.g. the technical
/// officer): the role-permissions endpoint resolves permissions by the full
/// (org, dept, role) triple, so a role with org/dept = 0 can't be edited here.
/// Those roles are seeded, not managed from this screen.
class _EditPermissionsButton extends StatelessWidget {
  final RoleAssignment role;

  const _EditPermissionsButton({required this.role});

  @override
  Widget build(BuildContext context) {
    final isGlobalRole = role.organizationId <= 0 || role.departmentId <= 0;
    if (isGlobalRole) return const SizedBox.shrink();

    final bloc = context.read<RolesBloc>();

    return IconButton(
      tooltip: 'تعديل الصلاحيات',
      icon: const Icon(Icons.tune_rounded,
          size: 22, color: AppColors.textSecondary),
      onPressed: () {
        bloc.add(OpenEditPermissions(
          organizationId: role.organizationId,
          departmentId: role.departmentId,
          roleId: role.roleId,
        ));
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: EditRolePermissionsDialog(role: role),
          ),
        );
      },
    );
  }
}

/// Active / inactive toggle. Replaces the edit/delete icons from the mock-up
/// because the backend only exposes create / list / toggle-status for roles.
class _StatusToggle extends StatelessWidget {
  final RoleAssignment role;
  final bool toggling;

  const _StatusToggle({required this.role, required this.toggling});

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
      value: role.isActive,
      activeColor: AppColors.primary,
      onChanged: (_) =>
          context.read<RolesBloc>().add(ToggleRoleStatus(role.id)),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          textDirection: monospace ? TextDirection.ltr : null,
          style: TextStyle(
            color: monospace ? AppColors.primary : AppColors.textPrimary,
            fontSize: monospace ? 13.5 : 15,
            fontWeight: FontWeight.w700,
            fontFeatures:
                monospace ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}
