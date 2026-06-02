import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';

class CreateDepartmentDialog extends StatefulWidget {
  const CreateDepartmentDialog({super.key});

  @override
  State<CreateDepartmentDialog> createState() => _CreateDepartmentDialogState();
}

class _CreateDepartmentDialogState extends State<CreateDepartmentDialog> {
  final _nameController = TextEditingController();
  int? _organizationId;
  int? _parentId;
  bool _touched = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    if (name.isEmpty || _organizationId == null) return;

    context.read<DepartmentsBloc>().add(
          CreateDepartmentRequested(
            name: name,
            organizationId: _organizationId!,
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

        // Parent options = departments inside the chosen organization.
        final parentOptions = {
          for (final d in state.departments)
            if (_organizationId == null || d.organizationId == _organizationId)
              d.id: d.name,
        };

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
                  _Header(onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Label('اسم القسم *'),
                        const SizedBox(height: 8),
                        _TextInput(
                          controller: _nameController,
                          hint: 'أدخل اسم القسم...',
                          errorText:
                              _touched && _nameController.text.trim().isEmpty
                                  ? 'هذا الحقل مطلوب'
                                  : null,
                        ),
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
                          onChanged: (v) => setState(() {
                            _organizationId = v;
                            _parentId = null; // reset parent when org changes
                          }),
                        ),
                        const SizedBox(height: 20),
                        const _Label('القسم الأب (اختياري)'),
                        const SizedBox(height: 8),
                        _IdDropdown(
                          hint: 'اختر القسم الأب...',
                          value: _parentId,
                          items: parentOptions,
                          onChanged: (v) => setState(() => _parentId = v),
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
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          const Text(
            'إنشاء قسم جديد',
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
                      'حفظ القسم',
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
