import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';

class CreateDepartmentDialog extends StatefulWidget {
  /// When opened inside a level, the new department inherits this parent and
  /// the parent picker is replaced by a fixed, read-only field.
  final int? fixedParentId;
  final String? fixedParentName;

  const CreateDepartmentDialog({
    super.key,
    this.fixedParentId,
    this.fixedParentName,
  });

  @override
  State<CreateDepartmentDialog> createState() => _CreateDepartmentDialogState();
}

class _CreateDepartmentDialogState extends State<CreateDepartmentDialog> {
  final _nameController = TextEditingController();
  // The organization is the user's active one, chosen once after login — no
  // per-form selection.
  late final int? _organizationId =
      getIt<ActiveOrganizationCubit>().activeOrgId;
  // The parent is inherited silently from the current drill-down level (null
  // at root). No picker is shown.
  late final int? _parentId = widget.fixedParentId;
  bool _touched = false;

  bool get _parentLocked => widget.fixedParentId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    final orgId = _organizationId;
    if (name.isEmpty || orgId == null) return;

    context.read<DepartmentsBloc>().add(
          CreateDepartmentRequested(
            name: name,
            organizationId: orgId,
            parentId: _parentId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DepartmentsBloc, DepartmentsState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إنشاء القسم بنجاح');
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر إنشاء القسم',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;
        final title = _parentLocked ? 'إضافة شعبة جديدة' : 'إنشاء قسم جديد';
        final nameLabel = _parentLocked ? 'اسم الشعبة *' : 'اسم القسم *';
        final nameHint =
            _parentLocked ? 'أدخل اسم الشعبة...' : 'أدخل اسم القسم...';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 620,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(title: title, onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Label(nameLabel),
                        const SizedBox(height: 8),
                        _TextInput(
                          controller: _nameController,
                          hint: nameHint,
                          errorText:
                              _touched && _nameController.text.trim().isEmpty
                                  ? 'هذا الحقل مطلوب'
                                  : null,
                        ),
                        const SizedBox(height: 26),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 18),
                        _Actions(
                          submitting: submitting,
                          saveLabel:
                              _parentLocked ? 'حفظ الشعبة' : 'حفظ القسم',
                          onSave: () => _submit(context),
                          onCancel: () => Navigator.pop(context),
                        ),
                      ],
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
  final String title;
  final VoidCallback onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool submitting;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _Actions({
    required this.submitting,
    required this.saveLabel,
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
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      saveLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
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
                  borderRadius: BorderRadius.circular(8),
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
