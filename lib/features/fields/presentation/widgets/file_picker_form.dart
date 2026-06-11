import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'dialog_kit.dart';
import 'field_form_kit.dart';
import 'field_type_card.dart';

class FilePickerForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const FilePickerForm({super.key, required this.meta});

  @override
  State<FilePickerForm> createState() => _FilePickerFormState();
}

class _FilePickerFormState extends State<FilePickerForm> {
  final _label = TextEditingController();
  final _maxSizeMb = TextEditingController(text: '5');
  final _extInput = TextEditingController();
  bool _isRequired = false;
  bool _allowMultiple = false;
  bool _touched = false;
  final List<String> _extensions = [];

  @override
  void dispose() {
    _label.dispose();
    _maxSizeMb.dispose();
    _extInput.dispose();
    super.dispose();
  }

  /// The hint promises 1–100 MB; enforce it before submitting.
  String? get _sizeError {
    final mb = int.tryParse(_maxSizeMb.text);
    if (mb == null || mb < 1 || mb > 100) {
      return 'القيمة يجب أن تكون بين 1 و 100';
    }
    return null;
  }

  void _addExtension() {
    final ext = _extInput.text.trim().toLowerCase();
    if (ext.isNotEmpty && !_extensions.contains(ext)) {
      setState(() {
        _extensions.add(ext);
        _extInput.clear();
      });
    }
  }

  void _submit(BuildContext ctx) {
    setState(() => _touched = true);
    if (_label.text.trim().isEmpty ||
        _extensions.isEmpty ||
        _sizeError != null) {
      return;
    }
    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: FieldType.filePicker,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
            'max_size_mb': int.parse(_maxSizeMb.text),
            'allowed_extensions': _extensions,
            'allow_multiple': _allowMultiple,
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        LabeledDialogInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: requiredError(_touched, _label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        LabeledDialogInput(
          label: 'الحجم الأقصى (MB) *',
          controller: _maxSizeMb,
          hint: 'مثال: 5 (بين 1 و 100)',
          numeric: true,
          errorText: _touched ? _sizeError : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        const DialogLabel('الامتدادات المسموحة *'),
        const SizedBox(height: 8),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: DialogTextInput(
                controller: _extInput,
                hint: 'مثال: pdf',
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addExtension,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                // Override the theme's full-width default
                // (minimumSize: Size(double.infinity, 58)) so this button
                // shrink-wraps instead of demanding infinite width as a
                // non-flex child of a Row.
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
        if (_touched && _extensions.isEmpty)
          const DialogErrorText('أضف امتداداً واحداً على الأقل'),
        if (_extensions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final ext in _extensions)
                Chip(
                  label: Text(ext),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _extensions.remove(ext)),
                  backgroundColor: AppColors.lightPrimary,
                  labelStyle: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                  deleteIconColor: AppColors.primary,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        LabeledSwitch(
          label: 'السماح بتحميل ملفات متعددة',
          value: _allowMultiple,
          onChanged: (v) => setState(() => _allowMultiple = v),
        ),
        const SizedBox(height: 8),
        LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}
