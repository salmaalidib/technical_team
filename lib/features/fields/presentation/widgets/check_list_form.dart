import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'field_form_kit.dart';
import 'field_options_editor.dart';
import 'field_type_card.dart';

class CheckListForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const CheckListForm({super.key, required this.meta});

  @override
  State<CheckListForm> createState() => _CheckListFormState();
}

class _CheckListFormState extends State<CheckListForm> {
  final _label = TextEditingController();
  final _minSelected = TextEditingController(text: '1');
  final _maxSelected = TextEditingController(text: '2');
  final _opts = OptionsManager();
  bool _isRequired = false;
  bool _touched = false;

  @override
  void dispose() {
    _label.dispose();
    _minSelected.dispose();
    _maxSelected.dispose();
    _opts.dispose();
    super.dispose();
  }

  /// min/max are required, must be ordered, and max can't exceed the number of
  /// options the user actually added.
  String? get _selectionError {
    final min = int.tryParse(_minSelected.text);
    final max = int.tryParse(_maxSelected.text);
    if (min == null || max == null) return 'أدخل حدّين صحيحين';
    if (min < 0) return 'الحد الأدنى لا يمكن أن يكون سالباً';
    if (min > max) return 'الحد الأدنى يجب ألا يتجاوز الحد الأقصى';
    final count = _opts.built.length;
    if (count > 0 && max > count) return 'الحد الأقصى يتجاوز عدد الخيارات';
    return null;
  }

  String? get _optionsError {
    if (!_touched) return null;
    if (_opts.built.isEmpty) return 'أضف خياراً واحداً على الأقل';
    if (_opts.hasDuplicates) return 'لا يمكن تكرار نفس الخيار';
    return null;
  }

  void _submit(BuildContext ctx) {
    setState(() => _touched = true);
    if (_label.text.trim().isEmpty ||
        _opts.built.isEmpty ||
        _opts.hasDuplicates ||
        _selectionError != null) {
      return;
    }
    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: FieldType.checkList,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
            'min_selected': int.parse(_minSelected.text),
            'max_selected': int.parse(_maxSelected.text),
            'options': _opts.built,
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
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: LabeledDialogInput(
                label: 'الحد الأدنى *',
                controller: _minSelected,
                hint: 'مثال: 1',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LabeledDialogInput(
                label: 'الحد الأقصى *',
                controller: _maxSelected,
                hint: 'مثال: 3',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_touched && _selectionError != null)
          DialogErrorText(_selectionError!),
        const SizedBox(height: 20),
        OptionsEditor(
          manager: _opts,
          onChanged: () => setState(() {}),
          errorText: _optionsError,
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
