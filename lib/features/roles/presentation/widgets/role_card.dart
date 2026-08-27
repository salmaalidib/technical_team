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
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowFaint,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(role: role, toggling: toggling),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            // The Camunda group key is shown next to the role name as
            // `roleCode`, so repeating it as its own field only made the card
            // taller without adding information.
            _InfoField(label: 'المؤسسة', value: role.organizationName ?? '—'),
            const SizedBox(height: 8),
            _InfoField(label: 'القسم', value: role.departmentName ?? '—'),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child:
              const Icon(Icons.shield_outlined, color: AppColors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.roleName,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        role.roleCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.code_rounded,
                        size: 13, color: AppColors.textSecondary),
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
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      icon: const Icon(Icons.tune_rounded,
          size: 19, color: AppColors.textSecondary),
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
        width: 40,
        height: 24,
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
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onChanged: (_) =>
          context.read<RolesBloc>().add(ToggleRoleStatus(role.id)),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

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
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
