import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/enums/form_status.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import '../bloc/fields_state.dart';
import 'dialog_kit.dart';
import 'field_type_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class CreateFieldDialog extends StatelessWidget {
  final FieldType type;

  const CreateFieldDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FieldsBloc, FieldsState>(
      listenWhen: (p, c) => p.createStatus != c.createStatus,
      listener: (context, state) {
        if (state.createStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم الإنشاء بنجاح');
          Navigator.of(context).pop();
        } else if (state.createStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.createError ?? 'تعذّر الإنشاء',
            isError: true,
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 680, maxHeight: 780),
            child: _FormBody(type: type),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form dispatcher — picks the right form widget per type
// ─────────────────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  final FieldType type;

  const _FormBody({required this.type});

  @override
  Widget build(BuildContext context) {
    final meta = kFieldTypeMeta[type]!;
    return switch (type) {
      FieldType.textField => _TextFieldForm(meta: meta),
      FieldType.radioGroup => _OptionsForm(type: type, meta: meta),
      FieldType.textDropdown => _OptionsForm(type: type, meta: meta),
      FieldType.checkList => _CheckListForm(meta: meta),
      FieldType.datePicker => _DatePickerForm(meta: meta),
      FieldType.filePicker => _FilePickerForm(meta: meta),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared scroll + action wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final String title;
  final bool submitting;
  final VoidCallback onSubmit;
  final List<Widget> children;

  const _DialogShell({
    required this.title,
    required this.submitting,
    required this.onSubmit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DialogHeader(
          title: title,
          onClose: () => Navigator.of(context).pop(),
        ),
        const Divider(height: 1, color: AppColors.border),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: DialogActions(
            submitting: submitting,
            saveLabel: 'إنشاء',
            onSave: onSubmit,
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

/// Wraps a form's body in the shared shell and rebuilds only the action bar
/// when `createStatus` flips to/from submitting. [onSubmit] receives a context
/// that can read the [FieldsBloc].
class _CreateFormScaffold extends StatelessWidget {
  final String title;
  final ValueChanged<BuildContext> onSubmit;
  final List<Widget> children;

  const _CreateFormScaffold({
    required this.title,
    required this.onSubmit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) => p.createStatus != c.createStatus,
      builder: (ctx, state) => _DialogShell(
        title: title,
        submitting: state.createStatus == FormStatus.submitting,
        onSubmit: () => onSubmit(ctx),
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small helpers
// ─────────────────────────────────────────────────────────────────────────────

/// The "this field is required" message, shown only after a submit attempt.
String? _requiredError(bool touched, TextEditingController c) =>
    touched && c.text.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

/// A label + text/number input pair, the building block every form repeats.
class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool numeric;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.errorText,
    this.onChanged,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DialogLabel(label),
        const SizedBox(height: 8),
        DialogTextInput(
          controller: controller,
          hint: hint,
          errorText: errorText,
          onChanged: onChanged,
          keyboardType: numeric ? TextInputType.number : null,
          inputFormatters:
              numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        ),
      ],
    );
  }
}

/// A bold label on one side and a [Switch] on the other.
class _LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// A small inline validation message (red, right-aligned).
class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Options editor — shared by RadioGroup / TextDropdown / CheckList
// ─────────────────────────────────────────────────────────────────────────────

/// Owns the dynamic list of option controllers and derives the submit payload.
/// The hosting [State] creates one, disposes it, and reads [built] on submit.
class _OptionsManager {
  final List<TextEditingController> controllers = [];

  _OptionsManager() {
    add();
  }

  void add() => controllers.add(TextEditingController());

  void removeAt(int i) => controllers.removeAt(i).dispose();

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
  }

  List<String> get _values => controllers
      .map((c) => c.text.trim())
      .where((v) => v.isNotEmpty)
      .toList();

  /// The UI collects only the value; the backend key is set equal to it.
  List<Map<String, String>> get built =>
      _values.map((v) => {'key': v, 'value': v}).toList();

  bool get hasDuplicates => _values.toSet().length != _values.length;
}

class _OptionsEditor extends StatelessWidget {
  final _OptionsManager manager;
  final VoidCallback onChanged;
  final String? errorText;

  const _OptionsEditor({
    required this.manager,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const DialogLabel('الخيارات *'),
            TextButton.icon(
              onPressed: () {
                manager.add();
                onChanged();
              },
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primary),
              label: const Text(
                'إضافة خيار',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (errorText != null) _ErrorText(errorText!),
        const SizedBox(height: 8),
        for (int i = 0; i < manager.controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: DialogTextInput(
                    controller: manager.controllers[i],
                    hint: 'أدخل الخيار...',
                    onChanged: (_) => onChanged(),
                  ),
                ),
                if (manager.controllers.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      manager.removeAt(i);
                      onChanged();
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 22),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. TextField form
// ─────────────────────────────────────────────────────────────────────────────

class _TextFieldForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const _TextFieldForm({required this.meta});

  @override
  State<_TextFieldForm> createState() => _TextFieldFormState();
}

class _TextFieldFormState extends State<_TextFieldForm> {
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
    return _CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        _LabeledInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: _requiredError(_touched, _label),
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
              child: _LabeledInput(
                label: 'الحد الأدنى للطول',
                controller: _minLength,
                hint: 'مثال: 2',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LabeledInput(
                label: 'الحد الأقصى للطول',
                controller: _maxLength,
                hint: 'مثال: 100',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_touched && _lengthError != null) _ErrorText(_lengthError!),
        const SizedBox(height: 20),
        _LabeledInput(
          label: 'النمط (Regex) — اختياري',
          controller: _regex,
          hint: 'مثال: ^[a-zA-Z]+\$',
        ),
        const SizedBox(height: 20),
        _LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2 & 3. RadioGroup / TextDropdown (shared options list)
// ─────────────────────────────────────────────────────────────────────────────

class _OptionsForm extends StatefulWidget {
  final FieldType type;
  final FieldTypeMeta meta;

  const _OptionsForm({required this.type, required this.meta});

  @override
  State<_OptionsForm> createState() => _OptionsFormState();
}

class _OptionsFormState extends State<_OptionsForm> {
  final _label = TextEditingController();
  final _opts = _OptionsManager();
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
    return _CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        _LabeledInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: _requiredError(_touched, _label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _OptionsEditor(
          manager: _opts,
          onChanged: () => setState(() {}),
          errorText: _optionsError,
        ),
        const SizedBox(height: 8),
        _LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CheckList form
// ─────────────────────────────────────────────────────────────────────────────

class _CheckListForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const _CheckListForm({required this.meta});

  @override
  State<_CheckListForm> createState() => _CheckListFormState();
}

class _CheckListFormState extends State<_CheckListForm> {
  final _label = TextEditingController();
  final _minSelected = TextEditingController(text: '1');
  final _maxSelected = TextEditingController(text: '2');
  final _opts = _OptionsManager();
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
    return _CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        _LabeledInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: _requiredError(_touched, _label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _LabeledInput(
                label: 'الحد الأدنى *',
                controller: _minSelected,
                hint: 'مثال: 1',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LabeledInput(
                label: 'الحد الأقصى *',
                controller: _maxSelected,
                hint: 'مثال: 3',
                numeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_touched && _selectionError != null) _ErrorText(_selectionError!),
        const SizedBox(height: 20),
        _OptionsEditor(
          manager: _opts,
          onChanged: () => setState(() {}),
          errorText: _optionsError,
        ),
        const SizedBox(height: 8),
        _LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. DatePicker form
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const _DatePickerForm({required this.meta});

  @override
  State<_DatePickerForm> createState() => _DatePickerFormState();
}

class _DatePickerFormState extends State<_DatePickerForm> {
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
    return _CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        _LabeledInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: _requiredError(_touched, _label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _LabeledInput(
                label: 'أدنى تاريخ * (YYYY-MM-DD)',
                controller: _minDate,
                hint: '1940-01-01',
                errorText: _dateError(_minDate),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LabeledInput(
                label: 'أقصى تاريخ * (YYYY-MM-DD)',
                controller: _maxDate,
                hint: '2030-12-31',
                errorText: _dateError(_maxDate),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_orderError != null) _ErrorText(_orderError!),
        const SizedBox(height: 20),
        _LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. FilePicker form
// ─────────────────────────────────────────────────────────────────────────────

class _FilePickerForm extends StatefulWidget {
  final FieldTypeMeta meta;

  const _FilePickerForm({required this.meta});

  @override
  State<_FilePickerForm> createState() => _FilePickerFormState();
}

class _FilePickerFormState extends State<_FilePickerForm> {
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
    return _CreateFormScaffold(
      title: 'إنشاء ${widget.meta.label}',
      onSubmit: _submit,
      children: [
        _LabeledInput(
          label: 'التسمية *',
          controller: _label,
          hint: 'أدخل تسمية الحقل...',
          errorText: _requiredError(_touched, _label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _LabeledInput(
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
          const _ErrorText('أضف امتداداً واحداً على الأقل'),
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
        _LabeledSwitch(
          label: 'السماح بتحميل ملفات متعددة',
          value: _allowMultiple,
          onChanged: (v) => setState(() => _allowMultiple = v),
        ),
        const SizedBox(height: 8),
        _LabeledSwitch(
          label: 'إلزامي',
          value: _isRequired,
          onChanged: (v) => setState(() => _isRequired = v),
        ),
      ],
    );
  }
}
