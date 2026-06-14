import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dropdown over an `{ id: name }` map that yields the selected int id.
///
/// Shared across create/edit dialogs so every id-picker looks identical (RTL,
/// white fill, primary focus border). Pass [errorText] to surface a validation
/// message for required selections.
class AppIdDropdown extends StatelessWidget {
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  const AppIdDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary),
      ),
      hint: Text(
        hint,
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<int>(
              value: e.key,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  e.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
