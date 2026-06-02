import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/roles_bloc.dart';
import '../bloc/roles_event.dart';
import '../bloc/roles_state.dart';

class CreateRoleDialog extends StatefulWidget {
  const CreateRoleDialog({super.key});

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  int? _organizationId;
  int? _departmentId;
  bool _touched = false;

  static final _codePattern = RegExp(r'^[A-Z0-9_]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? get _codeError {
    final code = _codeController.text.trim();
    if (code.isEmpty) return 'هذا الحقل مطلوب';
    if (code.length < 2) return 'حرفان على الأقل';
    if (!_codePattern.hasMatch(code)) {
      return 'أحرف إنجليزية كبيرة وأرقام وشرطة سفلية فقط';
    }
    return null;
  }

  void _onOrganizationChanged(int? value) {
    setState(() {
      _organizationId = value;
      _departmentId = null; // a new organization has its own departments
    });
    if (value != null) {
      context.read<RolesBloc>().add(LoadLeafDepartments(value));
    }
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        _codeError != null ||
        _organizationId == null ||
        _departmentId == null) {
      return;
    }

    context.read<RolesBloc>().add(
          CreateRoleRequested(
            name: name,
            code: _codeController.text.trim(),
            organizationId: _organizationId!,
            departmentId: _departmentId!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 32 < 620.0 ? screenWidth - 32 : 620.0;
    final narrow = dialogWidth < 520;

    return BlocConsumer<RolesBloc, RolesState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إنشاء الدور بنجاح');
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر إنشاء الدور',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _nameAndCode(narrow),
                          const SizedBox(height: 20),
                          const _Label('المؤسسة *'),
                          const SizedBox(height: 8),
                          _IdDropdown(
                            hint: 'اختر المؤسسة...',
                            value: _organizationId,
                            items: {
                              for (final o in state.organizations) o.id: o.name,
                            },
                            errorText: _touched && _organizationId == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: _onOrganizationChanged,
                          ),
                          const SizedBox(height: 20),
                          const _Label('القسم *'),
                          const SizedBox(height: 8),
                          _DepartmentField(
                            state: state,
                            organizationId: _organizationId,
                            value: _departmentId,
                            showError: _touched && _departmentId == null,
                            onChanged: (v) => setState(() => _departmentId = v),
                          ),
                          const SizedBox(height: 26),
                          const Divider(height: 1, color: AppColors.border),
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

  Widget _nameAndCode(bool narrow) {
    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('اسم الدور *'),
        const SizedBox(height: 8),
        _TextInput(
          controller: _nameController,
          hint: 'مثال: مدير الدائرة',
          errorText: _touched && _nameController.text.trim().isEmpty
              ? 'هذا الحقل مطلوب'
              : null,
        ),
      ],
    );

    final codeField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('كود الدور *'),
        const SizedBox(height: 8),
        _TextInput(
          controller: _codeController,
          hint: 'MANAGER',
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.toUpperCase(),
              ),
            ),
          ],
          errorText: _touched ? _codeError : null,
          helperText: 'سيتم استخدامه في توليد مفتاح Camunda',
        ),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          const SizedBox(height: 20),
          codeField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: nameField),
        const SizedBox(width: 16),
        Expanded(child: codeField),
      ],
    );
  }
}

/// Department dropdown driven by the leaves loaded for the selected
/// organization. Disabled until an organization is picked; shows a spinner
/// while the leaves load.
class _DepartmentField extends StatelessWidget {
  final RolesState state;
  final int? organizationId;
  final int? value;
  final bool showError;
  final ValueChanged<int?> onChanged;

  const _DepartmentField({
    required this.state,
    required this.organizationId,
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (organizationId == null) {
      return const _DisabledField(text: 'اختر المؤسسة أولاً');
    }

    final loadingThisOrg = state.leafStatus == RequestStatus.loading &&
        state.leafOrgId == organizationId;
    if (loadingThisOrg) {
      return const _DisabledField(
        text: 'جاري تحميل الأقسام...',
        showSpinner: true,
      );
    }

    if (state.leafStatus == RequestStatus.success &&
        state.leafDepartments.isEmpty) {
      return const _DisabledField(text: 'لا توجد أقسام لهذه المؤسسة');
    }

    return _IdDropdown(
      hint: 'اختر القسم...',
      value: value,
      items: {for (final d in state.leafDepartments) d.id: d.name},
      errorText: showError ? 'هذا الحقل مطلوب' : null,
      onChanged: onChanged,
    );
  }
}

class _DisabledField extends StatelessWidget {
  final String text;
  final bool showSpinner;

  const _DisabledField({required this.text, this.showSpinner = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          const Text(
            'إنشاء دور جديد',
            style: TextStyle(
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
  final String? helperText;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.errorText,
    this.helperText,
    this.textDirection,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: textDirection ?? TextDirection.rtl,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        helperMaxLines: 2,
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

class _IdDropdown extends StatelessWidget {
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  const _IdDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      hint: Text(
        hint,
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<int>(
              value: e.key,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  e.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
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
                  : const Text(
                      'حفظ الدور',
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
