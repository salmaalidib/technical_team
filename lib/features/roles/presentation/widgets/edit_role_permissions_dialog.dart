import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/role_assignment.dart';
import '../bloc/roles_bloc.dart';
import '../bloc/roles_event.dart';
import '../bloc/roles_state.dart';
import 'permission_picker.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Edits the permissions attached to an existing role.
///
/// Opens pre-checked with the role's current permissions and saves the whole
/// set via PUT (replace) — unticking every box clears all permissions, which
/// the backend allows.
///
/// Expects the surrounding [RolesBloc] to be provided by the caller (the roles
/// page), and an [OpenEditPermissions] event to have been dispatched so the
/// current permissions load.
class EditRolePermissionsDialog extends StatefulWidget {
  final RoleAssignment role;

  const EditRolePermissionsDialog({super.key, required this.role});

  @override
  State<EditRolePermissionsDialog> createState() =>
      _EditRolePermissionsDialogState();
}

class _EditRolePermissionsDialogState
    extends State<EditRolePermissionsDialog> {
  /// Null until the current permissions finish loading, then seeded from them.
  /// After that it's the user's working selection.
  Set<int>? _selectedIds;

  void _submit(BuildContext context) {
    final selected = _selectedIds;
    if (selected == null) return; // still loading

    context.read<RolesBloc>().add(
          SaveEditedPermissions(
            organizationId: widget.role.organizationId,
            departmentId: widget.role.departmentId,
            roleId: widget.role.roleId,
            permissionIds: selected.toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 32 < 620.0 ? screenWidth - 32 : 620.0;

    return BlocConsumer<RolesBloc, RolesState>(
      listenWhen: (p, c) =>
          p.editFormStatus != c.editFormStatus ||
          p.editPermsStatus != c.editPermsStatus,
      listener: (context, state) {
        // Seed the selection once the current permissions arrive.
        if (state.editPermsStatus == RequestStatus.success &&
            _selectedIds == null) {
          setState(() => _selectedIds = {...state.editInitialIds});
        }

        if (state.editFormStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم تحديث صلاحيات الدور');
          Navigator.of(context).pop();
        } else if (state.editFormStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.editFormError ?? 'تعذّر تحديث الصلاحيات',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting = state.editFormStatus == FormStatus.submitting;
        final loading = state.editPermsStatus == RequestStatus.loading ||
            state.editPermsStatus == RequestStatus.initial;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    roleName: widget.role.roleName,
                    onClose: () => Navigator.pop(context),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PermissionPicker(
                                  status: state.permissionsStatus,
                                  permissions: state.permissions,
                                  selectedIds: _selectedIds ?? const {},
                                  onChanged: (ids) =>
                                      setState(() => _selectedIds = ids),
                                ),
                                const SizedBox(height: 22),
                                const Divider(
                                    height: 1, color: AppColors.border),
                                const SizedBox(height: 18),
                                _Actions(
                                  submitting: submitting,
                                  onSave: () => _submit(context),
                                  onCancel: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String roleName;
  final VoidCallback onClose;

  const _Header({required this.roleName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعديل الصلاحيات',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 24, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _Actions({
    required this.submitting,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'حفظ التعديلات',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextButton(
              onPressed: submitting ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
