import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/searchable_field_dropdown.dart';
import '../../../fields/domain/entities/field_type.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
import '../../domain/entities/extracted_field.dart';

/// Step-2 picker: one card per **extracted PDF field**, grouped like step 4 of
/// the process builder. For each PDF field the technician links a field from the
/// shared library (of the matching type) via a searchable, paginated dropdown;
/// the chosen library field's full definition (label / options / constraints) is
/// reused, but its `data.id` is **forced to the PDF field name** so the backend
/// can fill that AcroForm field at PDF-generation time.
///
/// `radio_group` and `file_picker` PDF fields are intentionally hidden — they
/// are not supported in document templates here.
class ExtractedFieldsPicker extends StatelessWidget {
  /// The extracted PDF fields (raw from the backend; filtered here).
  final List<ExtractedField> fields;

  /// PDF-field-id → the linked widget (whose `data.id` == the PDF field id).
  /// Absent / null means "not yet linked".
  final Map<String, WidgetConfig?> links;

  /// Reports a link/unlink for [pdfField]. [widget] is null to clear.
  final void Function(ExtractedField pdfField, WidgetConfig? widget) onLink;

  const ExtractedFieldsPicker({
    super.key,
    required this.fields,
    required this.links,
    required this.onLink,
  });

  /// Supported widget types only — radio_group and file_picker are excluded.
  static const supportedTypes = {
    'text_field',
    'dropdown',
    'check_list',
    'date_picker',
  };

  /// backend widget_type → (FieldType for the dropdown/dialog, Arabic title).
  static const _typeMeta = <String, (FieldType, String)>{
    'text_field': (FieldType.textField, 'حقل نص'),
    'dropdown': (FieldType.textDropdown, 'قائمة منسدلة'),
    'check_list': (FieldType.checkList, 'قائمة تحقق'),
    'date_picker': (FieldType.datePicker, 'منتقي تاريخ'),
  };

  /// The supported PDF fields, in extraction order (what the cards render).
  static List<ExtractedField> supportedFields(List<ExtractedField> fields) =>
      fields.where((f) => supportedTypes.contains(f.widgetType)).toList();

  @override
  Widget build(BuildContext context) {
    final supported = supportedFields(fields);

    if (supported.isEmpty) {
      return const _EmptyHint(
        'لا توجد حقول قابلة للربط في هذا الملف. تأكد أن الـ PDF يحتوي حقول '
        'AcroForm من الأنواع المدعومة (نص / قائمة / تحقق / تاريخ).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pdfField in supported) ...[
          _ExtractedFieldCard(
            pdfField: pdfField,
            fieldType: _typeMeta[pdfField.widgetType]?.$1,
            typeTitle:
                _typeMeta[pdfField.widgetType]?.$2 ?? pdfField.widgetType,
            linked: links[pdfField.id],
            onLink: onLink,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Rebuilds [source] so its `data.id` (and inner `data['id']`) equals the PDF
/// field name, keeping the rest of the library definition intact.
WidgetConfig bindWidgetToPdfField(WidgetConfig source, String pdfFieldId) {
  final data = Map<String, dynamic>.from(source.data)..['id'] = pdfFieldId;
  return WidgetConfig(
    widgetType: source.widgetType,
    groupId: source.groupId,
    widgetId: pdfFieldId,
    label: source.label,
    data: data,
  );
}

class _ExtractedFieldCard extends StatelessWidget {
  final ExtractedField pdfField;
  final FieldType? fieldType;
  final String typeTitle;
  final WidgetConfig? linked;
  final void Function(ExtractedField pdfField, WidgetConfig? widget) onLink;

  const _ExtractedFieldCard({
    required this.pdfField,
    required this.fieldType,
    required this.typeTitle,
    required this.linked,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = linked != null;
    final type = fieldType;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLinked ? AppColors.primary : AppColors.border,
          width: isLinked ? 1.6 : 1.2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLinked
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isLinked ? Icons.check_rounded : Icons.text_fields_rounded,
                  color: isLinked ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Flexible(
                          child: Text(
                            pdfField.id,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Badge(label: typeTitle, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLinked
                          ? 'مربوط بـ: ${linked!.label}'
                          : 'حقل في الـ PDF — اربطه بحقل من المكتبة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isLinked
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (type == null)
            const Text(
              'نوع غير مدعوم',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            SearchableFieldDropdown(
              type: type,
              title: typeTitle,
              mode: FieldDropdownMode.single,
              // Single mode: the linked widget's id is rebound to the PDF field
              // id, so the bloc can't resolve its label — pass it explicitly.
              selectedIds: const {},
              triggerLabel: linked?.label,
              onPicked: (w) {
                if (w == null) {
                  onLink(pdfField, null);
                } else {
                  onLink(pdfField, bindWidgetToPdfField(w, pdfField.id));
                }
              },
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
