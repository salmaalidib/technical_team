import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/date_bound.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'date_bound_field.dart';
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

  /// Each end starts as a plain date; [DateBoundField] can switch it to a
  /// today-relative rule that the backend re-evaluates on every form open.
  DateBound _minDate = const AbsoluteDateBound('');
  DateBound _maxDate = const AbsoluteDateBound('');

  bool _isRequired = false;
  bool _touched = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  /// Per-end error: an absolute bound must be a well-formed date. Dynamic
  /// bounds are always valid on their own — only their order can be wrong.
  String? _boundError(DateBound bound) {
    if (!_touched) return null;
    if (bound is! AbsoluteDateBound) return null;
    if (bound.date.trim().isEmpty) return 'مطلوب';
    if (!bound.isValid) return 'صيغة غير صحيحة (YYYY-MM-DD)';
    return null;
  }

  bool get _boundsWellFormed =>
      _boundError(_minDate) == null && _boundError(_maxDate) == null;

  /// Compared on the resolved dates, so a relative bound is ordered against an
  /// absolute one the same way the backend does it.
  String? get _orderError {
    if (!_touched || !_boundsWellFormed) return null;
    if (_minDate.resolve().isAfter(_maxDate.resolve())) {
      return 'التاريخ الأدنى يجب ألا يتجاوز الأقصى';
    }
    return null;
  }

  void _submit(BuildContext ctx) {
    setState(() => _touched = true);

    if (_label.text.trim().isEmpty ||
        !_boundsWellFormed ||
        _minDate.resolve().isAfter(_maxDate.resolve())) {
      return;
    }

    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: FieldType.datePicker,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
            'min_date': _minDate.toJson(),
            'max_date': _maxDate.toJson(),
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
        DateBoundField(
          label: 'أدنى تاريخ *',
          value: _minDate,
          hint: '1940-01-01',
          errorText: _boundError(_minDate),
          onChanged: (b) => setState(() => _minDate = b),
        ),
        const SizedBox(height: 20),
        DateBoundField(
          label: 'أقصى تاريخ *',
          value: _maxDate,
          hint: '2030-12-31',
          errorText: _boundError(_maxDate),
          onChanged: (b) => setState(() => _maxDate = b),
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
