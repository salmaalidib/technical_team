import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_state.dart';
import 'dialog_kit.dart';

/// Shared building blocks for the six create-field forms. Kept here so each
/// form file stays small and the forms remain visually identical.

/// The "this field is required" message, shown only after a submit attempt.
String? requiredError(bool touched, TextEditingController c) =>
    touched && c.text.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

/// A small inline validation message (red, right-aligned).
class DialogErrorText extends StatelessWidget {
  final String message;

  const DialogErrorText(this.message, {super.key});

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

/// A label + text/number input pair, the building block every form repeats.
class LabeledDialogInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool numeric;

  const LabeledDialogInput({
    super.key,
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
class LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LabeledSwitch({
    super.key,
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
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Header + scrollable body + action bar, shared by every create-field form.
class DialogShell extends StatelessWidget {
  final String title;
  final bool submitting;
  final VoidCallback onSubmit;
  final List<Widget> children;

  const DialogShell({
    super.key,
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

/// Wraps a form's body in [DialogShell] and rebuilds only the action bar when
/// `createStatus` flips to/from submitting. [onSubmit] receives a context that
/// can read the [FieldsBloc].
class CreateFormScaffold extends StatelessWidget {
  final String title;
  final ValueChanged<BuildContext> onSubmit;
  final List<Widget> children;

  const CreateFormScaffold({
    super.key,
    required this.title,
    required this.onSubmit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) => p.createStatus != c.createStatus,
      builder: (ctx, state) => DialogShell(
        title: title,
        submitting: state.createStatus == FormStatus.submitting,
        onSubmit: () => onSubmit(ctx),
        children: children,
      ),
    );
  }
}
