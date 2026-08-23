import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_id_dropdown.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';
import 'add_location_dialog.dart';
import '../../../../shared/theme/app_dimens.dart';

class CreateInstitutionDialog extends StatefulWidget {
  /// When opened inside a level, the new institution inherits this parent and
  /// no parent picker is shown.
  final int? fixedParentId;
  final String? fixedParentName;

  const CreateInstitutionDialog({
    super.key,
    this.fixedParentId,
    this.fixedParentName,
  });

  @override
  State<CreateInstitutionDialog> createState() =>
      _CreateInstitutionDialogState();
}

class _CreateInstitutionDialogState extends State<CreateInstitutionDialog> {
  final _nameController = TextEditingController();
  // The parent is inherited silently from the current drill-down level (null
  // at root). No picker is shown.
  late final int? _parentId = widget.fixedParentId;
  int? _locationId;
  bool _nameTouched = false;

  bool get _parentLocked => widget.fixedParentId != null;

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

  /// Opens the "add location" dialog, sharing this dialog's [InstitutionsBloc]
  /// so the created location lands in the same state and dropdown.
  void _openAddLocation(BuildContext context) {
    final bloc = context.read<InstitutionsBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddLocationDialog(),
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
        final submitting = state.formStatus == FormStatus.submitting;
        final title = _parentLocked ? 'إضافة مؤسسة تابعة' : 'إنشاء مؤسسة جديدة';
        final nameLabel =
            _parentLocked ? 'اسم المؤسسة التابعة *' : 'اسم المؤسسة *';
        final nameHint = _parentLocked
            ? 'أدخل اسم المؤسسة التابعة...'
            : 'أدخل اسم المؤسسة...';
        final subtitle = _parentLocked
            ? 'ستُضاف ضمن: ${widget.fixedParentName}'
            : 'قم بإدخال بيانات المؤسسة الجديدة';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: 620,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogHeader(
                      title: title, onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DialogSubtitle(text: subtitle),
                        const SizedBox(height: 30),
                        _FieldLabel(nameLabel),
                        const SizedBox(height: 8),
                        _TextInput(
                          controller: _nameController,
                          hint: nameHint,
                          errorText: _nameTouched &&
                                  _nameController.text.trim().isEmpty
                              ? 'هذا الحقل مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const _FieldLabel('الموقع (اختياري)'),
                            const Spacer(),
                            _AddLocationButton(
                              onTap: () => _openAddLocation(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppIdDropdown(
                          hint: state.locations.isEmpty
                              ? 'لا توجد مواقع — أضف موقعًا'
                              : 'اختر الموقع...',
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
  final String title;
  final VoidCallback onClose;

  const _DialogHeader({required this.title, required this.onClose});

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
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
  final String text;

  const _DialogSubtitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.apartment_outlined,
            color: AppColors.primary, size: 25),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
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

/// Small pill button beside the location label that opens the add-location
/// dialog. Kept compact so it reads as a secondary action.
class _AddLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddLocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'إضافة موقع',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
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
                      'حفظ',
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
