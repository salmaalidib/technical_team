import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import 'dialog_kit.dart';
import 'field_form_kit.dart';

/// Owns the dynamic list of option controllers and derives the submit payload.
/// The hosting [State] creates one, disposes it, and reads [built] on submit.
///
/// When [withKeys] is true (radio groups), the user also types a `key` per
/// option that must match the Camunda variable; otherwise the key mirrors the
/// value.
class OptionsManager {
  final bool withKeys;
  final List<TextEditingController> controllers = [];
  final List<TextEditingController> keyControllers = [];

  OptionsManager({this.withKeys = false}) {
    add();
  }

  void add() {
    controllers.add(TextEditingController());
    if (withKeys) keyControllers.add(TextEditingController());
  }

  void removeAt(int i) {
    controllers.removeAt(i).dispose();
    if (withKeys) keyControllers.removeAt(i).dispose();
  }

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final c in keyControllers) {
      c.dispose();
    }
  }

  List<String> get _values => controllers
      .map((c) => c.text.trim())
      .where((v) => v.isNotEmpty)
      .toList();

  /// The option payload. Without keys the backend key mirrors the value; with
  /// keys (radio) each option carries the user-entered Camunda key.
  List<Map<String, String>> get built {
    if (!withKeys) {
      return _values.map((v) => {'key': v, 'value': v}).toList();
    }
    final out = <Map<String, String>>[];
    for (int i = 0; i < controllers.length; i++) {
      final value = controllers[i].text.trim();
      if (value.isEmpty) continue;
      final key = keyControllers[i].text.trim();
      out.add({'key': key.isEmpty ? value : key, 'value': value});
    }
    return out;
  }

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
        if (manager.withKeys)
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'المفتاح (key) يجب أن يطابق تماماً اسم المتغيّر في Camunda، '
              'وإلا لن تُربط قيمة الخيار بالعملية.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        for (int i = 0; i < manager.controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: manager.withKeys
                      ? Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: DialogTextInput(
                                controller: manager.controllers[i],
                                hint: 'أدخل الخيار...',
                                onChanged: (_) => onChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DialogTextInput(
                                controller: manager.keyControllers[i],
                                hint: 'المفتاح (نفس Camunda)...',
                                onChanged: (_) => onChanged(),
                              ),
                            ),
                          ],
                        )
                      : DialogTextInput(
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
