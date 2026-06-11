import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import 'dialog_kit.dart';
import 'field_form_kit.dart';

/// Owns the dynamic list of option controllers and derives the submit payload.
/// The hosting [State] creates one, disposes it, and reads [built] on submit.
class OptionsManager {
  final List<TextEditingController> controllers = [];

  OptionsManager() {
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

/// Renders the "options" header, add button, the dynamic rows, and an optional
/// inline error. State lives in the host via [manager]; [onChanged] should
/// trigger a rebuild (setState).
class OptionsEditor extends StatelessWidget {
  final OptionsManager manager;
  final VoidCallback onChanged;
  final String? errorText;

  const OptionsEditor({
    super.key,
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
        if (errorText != null) DialogErrorText(errorText!),
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
