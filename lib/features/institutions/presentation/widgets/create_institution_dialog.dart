import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';

class CreateInstitutionDialog extends StatefulWidget {
  const CreateInstitutionDialog({super.key});

  @override
  State<CreateInstitutionDialog> createState() =>
      _CreateInstitutionDialogState();
}

class _CreateInstitutionDialogState extends State<CreateInstitutionDialog> {
  final _nameController = TextEditingController();
  int? _parentId;
  int? _locationId;
  bool _nameTouched = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    setState(() => _nameTouched = true);
    if (name.isEmpty) return;

    context.read<InstitutionsBloc>().add(
          CreateInstitutionRequested(
            name: name,
            parentId: _parentId,
            locationId: _locationId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstitutionsBloc, InstitutionsState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إنشاء المؤسسة بنجاح');
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر إنشاء المؤسسة',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting =
            state.formStatus == FormStatus.submitting;

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
                  _DialogHeader(onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _DialogSubtitle(),
                        const SizedBox(height: 30),
                        const _FieldLabel('اسم المؤسسة *'),
                        const SizedBox(height: 8),
                        _TextInput(
                          controller: _nameController,
                          hint: 'أدخل اسم المؤسسة...',
                          errorText: _nameTouched &&
                                  _nameController.text.trim().isEmpty
                              ? 'هذا الحقل مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('المؤسسة الأم (اختياري)'),
                        const SizedBox(height: 8),
                        _IdDropdown(
                          hint: 'اختر المؤسسة الأم...',
                          value: _parentId,
                          items: {
                            for (final i in state.institutions) i.id: i.name,
                          },
                          onChanged: (v) => setState(() => _parentId = v),
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('الموقع (اختياري)'),
                        const SizedBox(height: 8),
                        _IdDropdown(
                          hint: 'اختر الموقع...',
                          value: _locationId,
                          items: {
                            for (final l in state.locations) l.id: l.name,
                          },
                          onChanged: (v) => setState(() => _locationId = v),
                        ),
                        const SizedBox(height: 28),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 18),
                        _DialogActions(
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

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          const Text(
            'إنشاء مؤسسة جديدة',
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
              child: const Icon(
                Icons.close_rounded,
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogSubtitle extends StatelessWidget {
  const _DialogSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.apartment_outlined, color: AppColors.primary, size: 25),
        SizedBox(width: 10),
        Text(
          'قم بإدخال بيانات المؤسسة الجديدة',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

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
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

/// Dropdown over an `{ id: name }` map that yields the selected int id.
class _IdDropdown extends StatelessWidget {
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?> onChanged;

  const _IdDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
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

class _DialogActions extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _DialogActions({
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
                      'حفظ المؤسسة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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
