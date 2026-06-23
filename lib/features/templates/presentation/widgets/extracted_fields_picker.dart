import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../fields/domain/entities/field_type.dart';
import '../../../fields/presentation/bloc/fields_bloc.dart';
import '../../../fields/presentation/bloc/fields_state.dart';
import '../../../fields/presentation/widgets/create_field_dialog.dart';
import '../../../process_builder/data/mappers/widget_config_mapper.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
import '../../domain/entities/extracted_field.dart';

/// Step-2 picker: one card per **extracted PDF field**, grouped like step 4 of
/// the process builder. For each PDF field the technician links a field from the
/// shared library (of the matching type); the chosen library field's full
/// definition (label / options / constraints) is reused, but its `data.id` is
/// **forced to the PDF field name** so the backend can fill that AcroForm field
/// at PDF-generation time.
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

  /// backend widget_type → (FieldType for the "+" dialog, Arabic title).
  static const _typeMeta = <String, (FieldType, String)>{
    'text_field': (FieldType.textField, 'حقل نص'),
    'dropdown': (FieldType.textDropdown, 'قائمة منسدلة'),
    'check_list': (FieldType.checkList, 'قائمة تحقق'),
    'date_picker': (FieldType.datePicker, 'منتقي تاريخ'),
  };

  /// The supported PDF fields, in extraction order (what the cards render).
  static List<ExtractedField> supportedFields(List<ExtractedField> fields) =>
      fields.where((f) => supportedTypes.contains(f.widgetType)).toList();

  static List<WidgetConfig> _libraryFrom(FieldsState f) => [
        ...f.textFields.map(WidgetConfigMapper.fromTextField),
        ...f.textDropdowns.map(WidgetConfigMapper.fromTextDropdown),
        ...f.checkLists.map(WidgetConfigMapper.fromCheckList),
        ...f.datePickers.map(WidgetConfigMapper.fromDatePicker),
      ];

  @override
  Widget build(BuildContext context) {
    final supported = supportedFields(fields);

    if (supported.isEmpty) {
      return const _EmptyHint(
        'لا توجد حقول قابلة للربط في هذا الملف. تأكد أن الـ PDF يحتوي حقول '
        'AcroForm من الأنواع المدعومة (نص / قائمة / تحقق / تاريخ).',
      );
    }

    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) =>
          p.loadStatus != c.loadStatus ||
          p.textFields != c.textFields ||
          p.textDropdowns != c.textDropdowns ||
          p.checkLists != c.checkLists ||
          p.datePickers != c.datePickers,
      builder: (context, fieldsState) {
        final library = _libraryFrom(fieldsState);
        final loading = fieldsState.loadStatus == RequestStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final pdfField in supported) ...[
              _ExtractedFieldCard(
                pdfField: pdfField,
                typeTitle: _typeMeta[pdfField.widgetType]?.$2 ??
                    pdfField.widgetType,
                addFieldType: _typeMeta[pdfField.widgetType]?.$1,
                linked: links[pdfField.id],
                options: library
                    .where((w) => w.widgetType == pdfField.widgetType)
                    .toList(),
                loading: loading,
                onLink: onLink,
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
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
  final String typeTitle;
  final FieldType? addFieldType;
  final WidgetConfig? linked;
  final List<WidgetConfig> options;
  final bool loading;
  final void Function(ExtractedField pdfField, WidgetConfig? widget) onLink;

  const _ExtractedFieldCard({
    required this.pdfField,
    required this.typeTitle,
    required this.addFieldType,
    required this.linked,
    required this.options,
    required this.loading,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = linked != null;

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
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _LibraryDropdown(
                  title: typeTitle,
                  options: options,
                  linkedLabel: linked?.label,
                  loading: loading,
                  onPick: (w) =>
                      onLink(pdfField, bindWidgetToPdfField(w, pdfField.id)),
                  onClear: () => onLink(pdfField, null),
                ),
              ),
              const SizedBox(width: 8),
              _AddButton(onTap: () => _createField(context)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createField(BuildContext context) async {
    final type = addFieldType;
    if (type == null) return;
    final fieldsBloc = context.read<FieldsBloc>();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => BlocProvider.value(
        value: fieldsBloc,
        child: CreateFieldDialog(type: type),
      ),
    );
  }
}

/// A single-select dropdown of library widgets. Shows the linked field's label
/// in the trigger; tapping an option links it, the "إلغاء الربط" row clears it.
class _LibraryDropdown extends StatelessWidget {
  final String title;
  final List<WidgetConfig> options;
  final String? linkedLabel;
  final bool loading;
  final void Function(WidgetConfig widget) onPick;
  final VoidCallback onClear;

  const _LibraryDropdown({
    required this.title,
    required this.options,
    required this.linkedLabel,
    required this.loading,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = linkedLabel != null;

    return PopupMenuButton<void>(
      tooltip: 'اختر $title...',
      enabled: !loading,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد عناصر — أنشئ واحداً عبر زر +',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else ...[
                      if (isLinked)
                        _Option(
                          label: 'إلغاء الربط',
                          danger: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            onClear();
                          },
                        ),
                      for (final w in options)
                        _Option(
                          label: w.label,
                          selected: w.label == linkedLabel,
                          onTap: () {
                            Navigator.of(context).pop();
                            onPick(w);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                isLinked ? linkedLabel! : 'اختر $title...',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isLinked ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: isLinked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    this.selected = false,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: danger ? AppColors.error : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
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
