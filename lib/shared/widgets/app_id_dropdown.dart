import 'package:flutter/material.dart';

import 'searchable_id_dropdown.dart';

/// Dropdown over an `{ id: name }` map that yields the selected int id.
///
/// Shared across create/edit dialogs so every id-picker looks identical (RTL,
/// white fill, primary focus border). Pass [errorText] to surface a validation
/// message for required selections.
///
/// Delegates to [SearchableIdDropdown]: the lists behind these pickers
/// (locations, location types, document types) grew past the point where
/// scrolling a plain Material menu was workable, so every id-picker now opens
/// a panel with a search box. The constructor is unchanged, so call sites keep
/// working as-is.
class AppIdDropdown extends StatelessWidget {
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  /// Label of the search box inside the panel; defaults to a generic "ابحث...".
  final String? searchHint;

  const AppIdDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    return SearchableIdDropdown(
      hint: hint,
      value: value,
      items: items,
      errorText: errorText,
      searchHint: searchHint,
      onChanged: onChanged,
    );
  }
}
