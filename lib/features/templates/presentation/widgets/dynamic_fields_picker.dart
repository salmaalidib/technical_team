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

/// Dynamic-fields picker for a document template — identical in behaviour and
/// look to the stage-customization step (`step4_customize_stages.dart`): one
/// multi-select dropdown per field type backed by the shared [FieldsBloc]
/// library, an inline `+` to create a new field, and selected fields rendered
/// as removable chips.
///
/// The parent owns the canonical [selected] list; toggles are reported through
/// [onToggle]. Requires a [FieldsBloc] in context.
class DynamicFieldsPicker extends StatelessWidget {
  final List<WidgetConfig> selected;
  final void Function(WidgetConfig widget, bool selected) onToggle;

  const DynamicFieldsPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  /// (FieldType, backend widget_type, Arabic title) — same set/order as step4.
  static const _dynTypes = <(FieldType, String, String)>[
    (FieldType.textField, 'text_field', 'حقل نص'),
    (FieldType.textDropdown, 'dropdown', 'قائمة منسدلة'),
    (FieldType.checkList, 'check_list', 'قائمة تحقق'),
    (FieldType.datePicker, 'date_picker', 'منتقي تاريخ'),
  ];

  static List<WidgetConfig> _libraryFrom(FieldsState f) => [
        ...f.textFields.map(WidgetConfigMapper.fromTextField),
        ...f.textDropdowns.map(WidgetConfigMapper.fromTextDropdown),
        ...f.radioGroups.map(WidgetConfigMapper.fromRadioGroup),
        ...f.checkLists.map(WidgetConfigMapper.fromCheckList),
        ...f.datePickers.map(WidgetConfigMapper.fromDatePicker),
        ...f.filePickers.map(WidgetConfigMapper.fromFilePicker),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) =>
          p.loadStatus != c.loadStatus ||
          p.textFields != c.textFields ||
          p.textDropdowns != c.textDropdowns ||
          p.radioGroups != c.radioGroups ||
          p.checkLists != c.checkLists ||
          p.datePickers != c.datePickers ||
          p.filePickers != c.filePickers,
      builder: (context, fieldsState) {
        final library = _libraryFrom(fieldsState);
        final loading = fieldsState.loadStatus == RequestStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (type, backendType, title) in _dynTypes) ...[
              _FieldTypeBlock(
                fieldType: type,
                backendType: backendType,
                title: title,
                options:
                    library.where((w) => w.widgetType == backendType).toList(),
                selected: selected
                    .where((w) => w.widgetType == backendType)
                    .toList(),
                loading: loading,
                onToggle: onToggle,
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _FieldTypeBlock extends StatelessWidget {
  final FieldType fieldType;
  final String backendType;
  final String title;
  final List<WidgetConfig> options;
  final List<WidgetConfig> selected;
  final bool loading;
  final void Function(WidgetConfig widget, bool selected) onToggle;

  const _FieldTypeBlock({
    required this.fieldType,
    required this.backendType,
    required this.title,
    required this.options,
    required this.selected,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIds = selected.map((w) => w.widgetId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniLabel('$title  (${selected.length})'),
        const SizedBox(height: 6),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _MultiSelectDropdown(
                hint: 'اختر $title...',
                options: options,
                selectedIds: selectedIds,
                loading: loading,
                onToggle: onToggle,
              ),
            ),
            const SizedBox(width: 8),
            _AddButton(onTap: () => _createField(context, fieldType)),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final w in selected)
                _SelectedChip(
                  label: w.label,
                  onRemove: () => onToggle(w, false),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _createField(BuildContext context, FieldType type) async {
    final fieldsBloc = context.read<FieldsBloc>();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => BlocProvider.value(
        value: fieldsBloc,
        child: CreateFieldDialog(type: type),
      ),
    );
    // FieldsBloc reloads the created type automatically; it then appears in
    // this type's dropdown for the user to link.
  }
}

/// A dropdown that opens a checkbox list (multi-select) anchored under the
/// field. Stays open while toggling; selected items also render as chips
/// outside. Handles large lists via an internal scroll view.
class _MultiSelectDropdown extends StatelessWidget {
  final String hint;
  final List<WidgetConfig> options;
  final Set<String> selectedIds;
  final bool loading;
  final void Function(WidgetConfig widget, bool selected) onToggle;

  const _MultiSelectDropdown({
    required this.hint,
    required this.options,
    required this.selectedIds,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final count = selectedIds.length;
    return PopupMenuButton<void>(
      tooltip: hint,
      enabled: !loading,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        final localSelected = {...selectedIds};
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setLocal) {
                if (options.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد عناصر — أنشئ واحداً عبر زر +',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final w in options)
                          InkWell(
                            onTap: () {
                              final nowSelected =
                                  !localSelected.contains(w.widgetId);
                              if (nowSelected) {
                                localSelected.add(w.widgetId);
                              } else {
                                localSelected.remove(w.widgetId);
                              }
                              onToggle(w, nowSelected);
                              setLocal(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Checkbox(
                                    value: localSelected.contains(w.widgetId),
                                    activeColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (v) {
                                      final sel = v ?? false;
                                      if (sel) {
                                        localSelected.add(w.widgetId);
                                      } else {
                                        localSelected.remove(w.widgetId);
                                      }
                                      onToggle(w, sel);
                                      setLocal(() {});
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      w.label,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
                count == 0 ? hint : '$count محدد',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: count == 0
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: count == 0 ? FontWeight.normal : FontWeight.w600,
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

class _SelectedChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _SelectedChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
