import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/dynamic_field.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import '../bloc/fields_state.dart';
import '../field_type_meta.dart';
import 'dialog_kit.dart';

class CreateFieldDialog extends StatefulWidget {
  /// When non-null the dialog is in edit mode (pre-filled, sends a PUT).
  final DynamicField? field;

  const CreateFieldDialog({super.key, this.field});

  @override
  State<CreateFieldDialog> createState() => _CreateFieldDialogState();
}

class _CreateFieldDialogState extends State<CreateFieldDialog> {
  final _nameController = TextEditingController();
  String? _type;
  List<TextEditingController> _listControllers = [];
  bool _touched = false;

  bool get _isEdit => widget.field != null;
  bool get _isList => _type != null && isListFieldType(_type!);

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    if (f != null) {
      _nameController.text = f.fieldName;
      _type = f.fieldType;
      if (f.listValues != null && f.listValues!.isNotEmpty) {
        _listControllers =
            f.listValues!.map((v) => TextEditingController(text: v)).toList();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _listControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(String? value) {
    setState(() {
      _type = value;
      if (_isList && _listControllers.isEmpty) {
        _listControllers = [TextEditingController()];
      }
    });
  }

  void _addValue() => setState(() {
        _listControllers.add(TextEditingController());
      });

  void _removeValue(int i) => setState(() {
        _listControllers.removeAt(i).dispose();
      });

  List<String> get _trimmedValues => _listControllers
      .map((c) => c.text.trim())
      .where((v) => v.isNotEmpty)
      .toList();

  String? get _listError {
    if (!_isList) return null;
    final values = _trimmedValues;
    if (values.isEmpty) return 'أضف قيمة واحدة على الأقل';
    if (values.toSet().length != values.length) {
      return 'القيم يجب أن تكون فريدة';
    }
    return null;
  }

  void _submit() {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    if (name.isEmpty || _type == null || _listError != null) return;

    context.read<FieldsBloc>().add(
          SaveFieldRequested(
            id: widget.field?.id,
            name: name,
            type: _type!,
            listValues: _isList ? _trimmedValues : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 32 < 620.0 ? screenWidth - 32 : 620.0;

    return BlocConsumer<FieldsBloc, FieldsState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(
            context,
            message: _isEdit ? 'تم تعديل الحقل بنجاح' : 'تم إنشاء الحقل بنجاح',
          );
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر حفظ الحقل',
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
                    title: _isEdit
                        ? 'تعديل حقل ديناميكي'
                        : 'إنشاء حقل ديناميكي جديد',
                    onClose: () => Navigator.pop(context),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const DialogLabel('اسم الحقل *'),
                          const SizedBox(height: 8),
                          DialogTextInput(
                            controller: _nameController,
                            hint: 'مثال: تاريخ الميلاد / birth_date',
                            errorText:
                                _touched && _nameController.text.trim().isEmpty
                                    ? 'هذا الحقل مطلوب'
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          const DialogLabel('نوع الحقل *'),
                          const SizedBox(height: 8),
                          _TypeDropdown(
                            value: _type,
                            errorText: _touched && _type == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: _onTypeChanged,
                          ),
                          if (_isList) ...[
                            const SizedBox(height: 20),
                            _ListEditor(
                              controllers: _listControllers,
                              onAdd: _addValue,
                              onRemove: _removeValue,
                              errorText: _touched ? _listError : null,
                            ),
                          ],
                          const SizedBox(height: 26),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 18),
                          DialogActions(
                            submitting: submitting,
                            saveLabel: 'حفظ الحقل',
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

class _ListEditor extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String? errorText;

  const _ListEditor({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogLabel('قيم القائمة *'),
        const SizedBox(height: 8),
        for (var i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: DialogTextInput(
                    controller: controllers[i],
                    hint: 'قيمة ${i + 1}',
                  ),
                ),
                if (controllers.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.error),
                    tooltip: 'حذف',
                  ),
                ],
              ],
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('إضافة قيمة'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final String? value;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: kFieldTypes.any((t) => t.value == value) ? value : null,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textPrimary),
      decoration: dialogDropdownDecoration(errorText),
      hint: const Text(
        'اختر نوع الحقل...',
        textAlign: TextAlign.right,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      items: kFieldTypes
          .map(
            (t) => DropdownMenuItem<String>(
              value: t.value,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(t.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    t.label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
