import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import 'field_form_kit.dart';
import 'field_options_editor.dart';
import 'field_type_card.dart';

/// Shared form for RadioGroup and TextDropdown — both are just a label plus a
/// list of options. [type] decides which create event is dispatched.
class OptionsForm extends StatefulWidget {
  final FieldType type;
  final FieldTypeMeta meta;

  const OptionsForm({super.key, required this.type, required this.meta});

  @override
  State<OptionsForm> createState() => _OptionsFormState();
}

class _OptionsFormState extends State<OptionsForm> {
  final _label = TextEditingController();
  final _opts = OptionsManager();
  bool _isRequired = false;
  bool _touched = false;

  @override
  void dispose() {
    _label.dispose();
    _opts.dispose();
    super.dispose();
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
        _opts.hasDuplicates) {
      return;
    }
    ctx.read<FieldsBloc>().add(CreateFieldRequested(
          type: widget.type,
          body: {
            'label': _label.text.trim(),
            'is_required': _isRequired,
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
