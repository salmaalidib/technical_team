import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Shared building blocks for the field / file create-edit dialogs, kept in one
/// place so both dialogs stay visually identical without duplication.

class DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const DialogHeader({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 24, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class DialogLabel extends StatelessWidget {
  final String text;

  const DialogLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class DialogTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const DialogTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary),
      ),
    );
  }
}

class DialogActions extends StatelessWidget {
  final bool submitting;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const DialogActions({
    super.key,
    required this.submitting,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      saveLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextButton(
              onPressed: submitting ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration dialogDropdownDecoration([String? errorText]) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    errorText: errorText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: _border(AppColors.border),
    enabledBorder: _border(AppColors.border),
    focusedBorder: _border(AppColors.primary),
  );
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
