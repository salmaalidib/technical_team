import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'dialog_kit.dart';
import 'field_form_kit.dart';
import 'field_type_card.dart';

class TextFieldForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const TextFieldForm({super.key, required this.meta});

  @override
  State<TextFieldForm> createState() => _TextFieldFormState();
}

class _TextFieldFormState extends State<TextFieldForm> {
  final _label = TextEditingController();
  final _regex = TextEditingController();
  final _maxLength = TextEditingController();
  final _minLength = TextEditingController();
  String _inputType = 'text';
  bool _isRequired = false;
  bool _touched = false;

  static const _inputTypes = ['text', 'string', 'int', 'phoneNumber', 'email'];

  @override
  void dispose() {
    _label.dispose();
    _regex.dispose();
    _maxLength.dispose();
    _minLength.dispose();
    super.dispose();
  }

  /// min/max length are both optional, but if both are given min must not
  /// exceed max.
  String? get _lengthError {
    final min = int.tryParse(_minLength.text);
    final max = int.tryParse(_maxLength.text);
    if (min != null && max != null && min > max) {
      return 'الحد الأدنى يجب ألا يتجاوز الحد الأقصى';
    }
    return null;
  }

  void _submit(BuildContext ctx) {
    setState(() => _touched = true);
    if (_label.text.trim().isEmpty || _lengthError != null) return;
    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: FieldType.textField,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
            'input_type': _inputType,
            if (_regex.text.trim().isNotEmpty) 'regex': _regex.text.trim(),
            if (_maxLength.text.isNotEmpty)
              'max_length': int.tryParse(_maxLength.text),
            if (_minLength.text.isNotEmpty)
              'min_length': int.tryParse(_minLength.text),
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
        const DialogLabel('نوع المدخل *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _inputType,
          decoration: dialogDropdownDecoration(),
          items: _inputTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _inputType = v ?? 'text'),
        ),
        const SizedBox(height: 20),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: LabeledDialogInput(
                label: 'الحد الأدنى للطول',
                controller: _minLength,
                hint: 'مثال: 2',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LabeledDialogInput(
                label: 'الحد الأقصى للطول',
                controller: _maxLength,
                hint: 'مثال: 100',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_touched && _lengthError != null) DialogErrorText(_lengthError!),
        const SizedBox(height: 20),
        LabeledDialogInput(
          label: 'النمط (Regex) — اختياري',
          controller: _regex,
          hint: 'مثال: ^[a-zA-Z]+\$',
        ),
        const SizedBox(height: 20),
        LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}
