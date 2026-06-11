import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'field_form_kit.dart';
import 'field_type_card.dart';

class DatePickerForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const DatePickerForm({super.key, required this.meta});

  @override
  State<DatePickerForm> createState() => _DatePickerFormState();
}

class _DatePickerFormState extends State<DatePickerForm> {
  final _label = TextEditingController();
  final _minDate = TextEditingController();
  final _maxDate = TextEditingController();
  bool _isRequired = false;
  bool _touched = false;

  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void dispose() {
    _label.dispose();
    _minDate.dispose();
    _maxDate.dispose();
    super.dispose();
  }

  bool _isValidDate(String s) =>
      _dateRe.hasMatch(s) && DateTime.tryParse(s) != null;

  /// Per-field error: required, then well-formed `YYYY-MM-DD`.
  String? _dateError(TextEditingController c) {
    if (!_touched) return null;
    final t = c.text.trim();
    if (t.isEmpty) return 'مطلوب';
    if (!_isValidDate(t)) return 'صيغة غير صحيحة (YYYY-MM-DD)';
    return null;
  }

  String? get _orderError {
    if (!_touched) return null;
    final min = _minDate.text.trim();
    final max = _maxDate.text.trim();
    if (_isValidDate(min) &&
        _isValidDate(max) &&
        DateTime.parse(min).isAfter(DateTime.parse(max))) {
      return 'التاريخ الأدنى يجب ألا يتجاوز الأقصى';
    }
    return null;
  }

  void _submit(BuildContext ctx) {
    setState(() => _touched = true);
    final min = _minDate.text.trim();
    final max = _maxDate.text.trim();
    if (_label.text.trim().isEmpty ||
        !_isValidDate(min) ||
        !_isValidDate(max) ||
        DateTime.parse(min).isAfter(DateTime.parse(max))) {
      return;
    }
    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: FieldType.datePicker,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
            'min_date': min,
            'max_date': max,
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
                label: 'أدنى تاريخ * (YYYY-MM-DD)',
                controller: _minDate,
                hint: '1940-01-01',
                errorText: _dateError(_minDate),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LabeledDialogInput(
                label: 'أقصى تاريخ * (YYYY-MM-DD)',
                controller: _maxDate,
                hint: '2030-12-31',
                errorText: _dateError(_maxDate),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_orderError != null) DialogErrorText(_orderError!),
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
