import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Renders a stage's `config_json` (the `config` field of `{id}/details`)
/// readably:
///   * `widgets[]` → one row per form field (type · label · required).
///   * `actions[]` → chips of service-task actions.
class StageConfigView extends StatelessWidget {
  final Map<String, dynamic> config;

  const StageConfigView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final widgets = (config['widgets'] as List?) ?? const [];
    final actions = (config['actions'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widgets.isNotEmpty) ...[
          const _SectionLabel('الحقول'),
          const SizedBox(height: 8),
          for (final w in widgets)
            if (w is Map) _WidgetRow(widget: w.cast<String, dynamic>()),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionLabel('الإجراءات'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in actions) _ActionChip(label: _actionLabel('$a')),
            ],
          ),
        ],
      ],
    );
  }

  static String _actionLabel(String raw) {
    switch (raw) {
      case 'GENERATE_PDF':
        return 'توليد PDF';
      case 'SEND_EMAIL':
        return 'إرسال بريد';
      case 'SEND_NOTIFICATION':
        return 'إرسال إشعار';
      default:
        return raw;
    }
  }
}

class _WidgetRow extends StatelessWidget {
  final Map<String, dynamic> widget;

  const _WidgetRow({required this.widget});

  @override
  Widget build(BuildContext context) {
    final data = (widget['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final type = (widget['widget_type'] ?? '').toString();
    final label = (data['label'] ?? data['id'] ?? '—').toString();
    final required = data['is_required'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(type), size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 6),
                      const Text('*',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w900)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_typeLabel(type)}${required ? ' · مطلوب' : ' · اختياري'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'text_field':
        return 'حقل نصي';
      case 'dropdown':
      case 'text_dropdown':
        return 'قائمة منسدلة';
      case 'radio_group':
        return 'اختيار واحد';
      case 'check_list':
        return 'قائمة تحقق';
      case 'date_picker':
        return 'تاريخ';
      case 'file_picker':
        return 'مرفق';
      default:
        return type.isEmpty ? 'حقل' : type;
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'text_field':
        return Icons.text_fields;
      case 'dropdown':
      case 'text_dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'radio_group':
        return Icons.radio_button_checked;
      case 'check_list':
        return Icons.checklist;
      case 'date_picker':
        return Icons.calendar_today_outlined;
      case 'file_picker':
        return Icons.attach_file;
      default:
        return Icons.input;
    }
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  const _ActionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}
