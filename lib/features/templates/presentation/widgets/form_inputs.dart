import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// A small labeled text field tuned for the template form (RTL, compact, white
/// fill). Used by the template's basic-info and form-settings inputs.
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, right: 2),
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: 1,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
