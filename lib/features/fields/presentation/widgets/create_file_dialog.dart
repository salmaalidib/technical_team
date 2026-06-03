import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/file_definition.dart';
import '../bloc/files_bloc.dart';
import '../bloc/files_event.dart';
import '../bloc/files_state.dart';
import 'dialog_kit.dart';

/// Backend-accepted values (see filesValidations.js).
const List<String> kFileTypes = ['pdf', 'docx', 'jpg', 'png'];
const List<String> kFileClassifications = [
  'اضبارة',
  'وثائق للمواطن',
  'كتاب وزاري',
];

class CreateFileDialog extends StatefulWidget {
  /// When non-null the dialog is in edit mode (pre-filled, sends a PUT).
  final FileDefinition? file;

  const CreateFileDialog({super.key, this.file});

  @override
  State<CreateFileDialog> createState() => _CreateFileDialogState();
}

class _CreateFileDialogState extends State<CreateFileDialog> {
  final _nameController = TextEditingController();
  String? _fileType;
  String? _classification;
  bool _touched = false;

  bool get _isEdit => widget.file != null;

  @override
  void initState() {
    super.initState();
    final f = widget.file;
    if (f != null) {
      _nameController.text = f.fileName;
      _fileType = kFileTypes.contains(f.fileType) ? f.fileType : null;
      _classification = kFileClassifications.contains(f.classification)
          ? f.classification
          : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    if (name.isEmpty || _fileType == null || _classification == null) return;

    context.read<FilesBloc>().add(
          SaveFileRequested(
            id: widget.file?.id,
            name: name,
            fileType: _fileType!,
            classification: _classification!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 32 < 620.0 ? screenWidth - 32 : 620.0;

    return BlocConsumer<FilesBloc, FilesState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(
            context,
            message:
                _isEdit ? 'تم تعديل التعريف بنجاح' : 'تم إنشاء التعريف بنجاح',
          );
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر حفظ التعريف',
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
                  DialogHeader(
                    title: _isEdit ? 'تعديل تعريف ملف' : 'إنشاء تعريف ملف جديد',
                    onClose: () => Navigator.pop(context),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _InfoNote(),
                          const SizedBox(height: 22),
                          const DialogLabel('اسم الملف *'),
                          const SizedBox(height: 8),
                          DialogTextInput(
                            controller: _nameController,
                            hint: 'مثال: نموذج طلب وثيقة رسمية',
                            onChanged: (_) => setState(() {}),
                            errorText:
                                _touched && _nameController.text.trim().isEmpty
                                    ? 'هذا الحقل مطلوب'
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          const DialogLabel('نوع الملف *'),
                          const SizedBox(height: 8),
                          _StringDropdown(
                            hint: 'اختر نوع الملف...',
                            value: _fileType,
                            items: {
                              for (final t in kFileTypes) t: t.toUpperCase(),
                            },
                            errorText: _touched && _fileType == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: (v) => setState(() => _fileType = v),
                          ),
                          const SizedBox(height: 20),
                          const DialogLabel('التصنيف *'),
                          const SizedBox(height: 8),
                          _StringDropdown(
                            hint: 'اختر التصنيف...',
                            value: _classification,
                            items: {
                              for (final c in kFileClassifications) c: c,
                            },
                            errorText: _touched && _classification == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: (v) =>
                                setState(() => _classification = v),
                          ),
                          const SizedBox(height: 24),
                          _Preview(
                            name: _nameController.text.trim(),
                            fileType: _fileType,
                            classification: _classification,
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 18),
                          DialogActions(
                            submitting: submitting,
                            saveLabel: 'حفظ التعريف',
                            onSave: _submit,
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

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.description_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'تعريف ملف قابل لإعادة الاستخدام',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'هذا ليس رفع ملف فعلي، بل تعريف لنوع ملف يمكن طلبه في المعاملات',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final String name;
  final String? fileType;
  final String? classification;

  const _Preview({
    required this.name,
    required this.fileType,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'معاينة التعريف',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _row('اسم الملف', name.isEmpty ? '-' : name),
        const SizedBox(height: 10),
        _row('نوع الملف', fileType?.toUpperCase() ?? '-'),
        const SizedBox(height: 10),
        _row('التصنيف', classification ?? '-'),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StringDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final Map<String, String> items;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _StringDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textPrimary),
      decoration: dialogDropdownDecoration(errorText),
      hint: Text(
        hint,
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.key,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  e.value,
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
