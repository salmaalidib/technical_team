import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Renders a stage's `config_json` (the `config` field of `{id}/details`) as a
/// human-readable summary — never as raw JSON:
///   * `widgets[]` → a card per form field (name · type · required · options).
///   * `actions[]` → a card per automated action, described from its payload.
///   * `requires_digital_signature` → a single note.
///
/// Anything the schema does not describe (technical ids, widget references,
/// unknown keys) is deliberately dropped rather than printed.
class StageConfigView extends StatelessWidget {
  final Map<String, dynamic> config;

  const StageConfigView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final widgets = <Map<String, dynamic>>[
      for (final w in (config['widgets'] as List?) ?? const [])
        if (w is Map) w.cast<String, dynamic>(),
    ];
    final actions = <_StageAction>[
      for (final a in (config['actions'] as List?) ?? const [])
        if (_StageAction.parse(a) case final action?) action,
    ];
    final signed = config['requires_digital_signature'] == true;

    if (widgets.isEmpty && actions.isEmpty && !signed) {
      return const _EmptyHint('لا توجد تفاصيل إضافية لهذه المرحلة');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widgets.isNotEmpty) ...[
          _SectionLabel('الحقول', count: widgets.length),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < widgets.length; i++) ...[
            _FieldTile(order: i + 1, widget: widgets[i]),
            if (i != widgets.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (actions.isNotEmpty) ...[
          if (widgets.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          _SectionLabel('الإجراءات التلقائية', count: actions.length),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < actions.length; i++) ...[
            _ActionTile(action: actions[i]),
            if (i != actions.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (signed) ...[
          if (widgets.isNotEmpty || actions.isNotEmpty)
            const SizedBox(height: AppSpacing.lg),
          const _SignatureNote(),
        ],
      ],
    );
  }
}

/// An entry of `actions[]`, normalised to what the user needs to see: a title,
/// an icon, and a plain-language description built from the payload.
///
/// The backend sends `{ name, payload }`, but older configs stored bare
/// strings; both are accepted. Actions outside the supported catalogue
/// (`SEND_EMAIL`, `SEND_NOTIFICATION`, `GENERATE_PDF`, `SYNC_SELF_CARD`) are
/// dropped so a machine code is never shown.
class _StageAction {
  final IconData icon;
  final String title;
  final String? description;

  const _StageAction({
    required this.icon,
    required this.title,
    this.description,
  });

  static _StageAction? parse(dynamic raw) {
    final String name;
    final Map<String, dynamic> payload;
    if (raw is Map) {
      name = (raw['name'] ?? '').toString();
      final p = raw['payload'];
      payload = p is Map ? p.cast<String, dynamic>() : const {};
    } else {
      name = '$raw';
      payload = const {};
    }

    switch (name) {
      case 'SEND_NOTIFICATION':
        return _StageAction(
          icon: Icons.notifications_active_rounded,
          title: 'إرسال إشعار',
          description: _text(payload['message']) ?? _text(payload['title']),
        );
      case 'SEND_EMAIL':
        return _StageAction(
          icon: Icons.mark_email_read_rounded,
          title: 'إرسال بريد إلكتروني',
          description: _text(payload['subject']) ?? _text(payload['message']),
        );
      case 'GENERATE_PDF':
        return const _StageAction(
          icon: Icons.picture_as_pdf_rounded,
          title: 'توليد ملف PDF',
          description: 'يُنشأ المستند تلقائيًا عند إتمام هذه المرحلة',
        );
      case 'SYNC_SELF_CARD':
        return _StageAction(
          icon: Icons.badge_rounded,
          title: 'تحديث البطاقة الذاتية',
          description: _selfCardTarget(_text(payload['target'])),
        );
      default:
        return null;
    }
  }

  static String? _text(dynamic value) {
    final s = (value ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Maps the `target` section of a self-card sync onto its Arabic name.
  static String? _selfCardTarget(String? target) {
    switch (target) {
      case 'profile_header':
        return 'يُسجَّل في البيانات الأساسية للموظف';
      case 'update_profile_header':
        return 'يُحدِّث البيانات الأساسية للموظف';
      case 'training_course':
        return 'يُسجَّل في الدورات التدريبية';
      case 'employment_status':
        return 'يُسجَّل في الحالة الوظيفية';
      case 'irregular_absence':
        return 'يُسجَّل في حالات الغياب';
      case 'leave':
        return 'يُسجَّل في الإجازات';
      case 'reward':
        return 'يُسجَّل في المكافآت';
      case 'sanction':
        return 'يُسجَّل في العقوبات';
      default:
        return null;
    }
  }
}

/// One form field, shown as a soft tile: order badge, label, type and options.
class _FieldTile extends StatelessWidget {
  final int order;
  final Map<String, dynamic> widget;

  const _FieldTile({required this.order, required this.widget});

  @override
  Widget build(BuildContext context) {
    final data = (widget['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final type = (widget['widget_type'] ?? '').toString();
    final label = _label(data);
    final required = data['is_required'] == true;
    final options = _options(data);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderBadge(order: order),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _RequirementTag(required: required),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_iconFor(type),
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      _typeLabel(type),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final o in options) _OptionChip(label: o),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The field's display name. Falls back to its type rather than exposing the
  /// technical `id` used by the engine.
  static String _label(Map<String, dynamic> data) {
    final raw = (data['label'] ?? '').toString().trim();
    return raw.isEmpty ? 'حقل بدون تسمية' : raw;
  }

  /// Human-readable choice list; the `key` half of each option is internal and
  /// is never displayed.
  static List<String> _options(Map<String, dynamic> data) {
    final raw = data['options'];
    if (raw is! List) return const [];
    final out = <String>[];
    for (final o in raw) {
      final value = o is Map ? (o['value'] ?? o['label']) : o;
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) out.add(text);
    }
    return out;
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'text_field':
        return 'حقل نصي';
      case 'dropdown':
      case 'text_dropdown':
        return 'قائمة اختيار وحيد';
      case 'radio_group':
        return 'اختيار واحد';
      case 'check_list':
        return 'اختيار من متعدد';
      case 'date_picker':
        return 'تاريخ';
      case 'file_picker':
        return 'مرفق';
      default:
        return 'حقل إدخال';
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'text_field':
        return Icons.text_fields_rounded;
      case 'dropdown':
      case 'text_dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'radio_group':
        return Icons.radio_button_checked_rounded;
      case 'check_list':
        return Icons.checklist_rounded;
      case 'date_picker':
        return Icons.calendar_today_rounded;
      case 'file_picker':
        return Icons.attach_file_rounded;
      default:
        return Icons.short_text_rounded;
    }
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;
  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lightPrimary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$order',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RequirementTag extends StatelessWidget {
  final bool required;
  const _RequirementTag({required this.required});

  @override
  Widget build(BuildContext context) {
    final color = required ? AppColors.errorDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.allPill,
      ),
      child: Text(
        required ? 'مطلوب' : 'اختياري',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  const _OptionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allXs,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textCharcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One automated action: icon, Arabic title and — where the payload carries
/// something meaningful — a short description of what it does.
class _ActionTile extends StatelessWidget {
  final _StageAction action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final description = action.description;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textCharcoal,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flags stages whose completion is sealed with a digital signature.
class _SignatureNote extends StatelessWidget {
  const _SignatureNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_user_rounded,
            size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'تتطلب هذه المرحلة توقيعًا رقميًا',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withOpacity(0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final int count;

  const _SectionLabel(this.text, {required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: AppRadius.allPill,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
    );
  }
}
