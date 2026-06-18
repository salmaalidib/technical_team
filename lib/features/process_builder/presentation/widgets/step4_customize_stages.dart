import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../fields/domain/entities/field_type.dart';
import '../../../fields/presentation/bloc/fields_bloc.dart';
import '../../../fields/presentation/bloc/fields_state.dart';
import '../../../fields/presentation/widgets/create_field_dialog.dart';
import '../../data/mappers/widget_config_mapper.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
import '../../domain/entities/widget_config.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_event.dart';
import '../bloc/process_builder_state.dart';
import 'wizard_kit.dart';

/// Step 4 — a vertical list of stage cards. Tapping a card expands its inline
/// editor (instead of a side panel).
class Step4CustomizeStages extends StatelessWidget {
  const Step4CustomizeStages({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessBuilderBloc, ProcessBuilderState>(
      builder: (context, state) {
        final stages = state.createdProcess?.stages ?? const <ProcessStage>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WizardSectionTitle('تخصيص خطوات المعاملة'),
            const SizedBox(height: 6),
            const Text(
              'اضغط على المرحلة لتخصيصها — مهام المستخدم تأخذ استمارة وتعيينات، '
              'ومهام النظام تأخذ إجراءات تلقائية.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            for (final stage in stages)
              _StageCard(
                stage: stage,
                draft: state.drafts[stage.id],
                expanded: state.expandedStageId == stage.id,
                state: state,
              ),
          ],
        );
      },
    );
  }
}

class _StageCard extends StatelessWidget {
  final ProcessStage stage;
  final StageConfigDraft? draft;
  final bool expanded;
  final ProcessBuilderState state;

  const _StageCard({
    required this.stage,
    required this.draft,
    required this.expanded,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? AppColors.primary : AppColors.border,
          width: expanded ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context
                .read<ProcessBuilderBloc>()
                .add(StageExpansionToggled(stage.id)),
            child: _CardHeader(stage: stage, draft: draft, expanded: expanded),
          ),
          if (expanded && draft != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: stage.isUserTask
                  ? _UserTaskEditor(state: state, draft: draft!)
                  : _ServiceTaskEditor(draft: draft!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final ProcessStage stage;
  final StageConfigDraft? draft;
  final bool expanded;

  const _CardHeader({
    required this.stage,
    required this.draft,
    required this.expanded,
  });

  String get _subtitle {
    if (stage.isUserTask) {
      final ready = draft?.isComplete ?? false;
      return ready ? 'مهمة مستخدم · مُهيّأة' : 'مهمة مستخدم · غير مُهيّأة';
    }
    final count = draft?.actions.length ?? 0;
    return count == 0 ? 'مهمة نظام · بدون إجراءات' : 'مهمة نظام · $count إجراء';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = stage.isUserTask;
    final accent = isUser ? AppColors.primary : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: expanded ? AppColors.primary : accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isUser ? Icons.shield_outlined : Icons.bolt_outlined,
              color: expanded ? Colors.white : accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Flexible(
                      child: Text(
                        stage.name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      label: isUser ? 'مهمة مستخدم' : 'مهمة نظام',
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════ USER TASK editor ════════════════════════
class _UserTaskEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _UserTaskEditor({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final stageId = draft.stage.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // assignment cascade (org → dept → role)
        const WizardLabel('التعيين — من ينفّذ المرحلة *'),
        const SizedBox(height: 8),
        const _MiniLabel('المؤسسة'),
        const SizedBox(height: 6),
        WizardDropdown<int>(
          hint: 'اختر المؤسسة...',
          value: draft.organizationId,
          items: {for (final o in state.organizations) o.id: o.name},
          onChanged: (v) => bloc.add(StageOrgChanged(stageId, v)),
        ),
        const SizedBox(height: 12),
        const _MiniLabel('القسم / الدائرة'),
        const SizedBox(height: 6),
        _DepartmentDropdown(state: state, draft: draft),
        const SizedBox(height: 12),
        const _MiniLabel('الدور'),
        const SizedBox(height: 6),
        _RoleDropdown(state: state, draft: draft),
        const SizedBox(height: 22),

        // dynamic fields — one multi-select dropdown per type + add button
        const WizardLabel('الحقول الديناميكية'),
        const SizedBox(height: 12),
        _DynamicFieldsEditor(draft: draft),
        const SizedBox(height: 20),

        // digital signature
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.inputBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                child: Text(
                  'يتطلب توقيعاً رقمياً',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: draft.requiresSignature,
                activeColor: AppColors.primary,
                onChanged: (v) => bloc.add(StageSignatureToggled(stageId, v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartmentDropdown extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _DepartmentDropdown({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    if (draft.organizationId == null) {
      return const _Hint('اختر المؤسسة أولاً');
    }
    if (state.leafStatus == RequestStatus.loading) {
      return const _Hint('جاري تحميل الأقسام...', spinner: true);
    }
    if (state.leafStatus == RequestStatus.success &&
        state.leafDepartments.isEmpty) {
      return const _Hint('لا توجد أقسام لهذه المؤسسة');
    }
    return WizardDropdown<int>(
      hint: 'اختر القسم...',
      value: draft.departmentId,
      items: {for (final d in state.leafDepartments) d.id: d.name},
      onChanged: (v) => bloc.add(StageDeptChanged(draft.stage.id, v)),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _RoleDropdown({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    if (draft.departmentId == null) {
      return const _Hint('اختر القسم أولاً');
    }
    if (state.rolesStatus == RequestStatus.loading) {
      return const _Hint('جاري تحميل الأدوار...', spinner: true);
    }
    if (state.rolesStatus == RequestStatus.success &&
        state.rolesByDepartment.isEmpty) {
      return const _Hint('لا توجد أدوار لهذا القسم');
    }
    return WizardDropdown<int>(
      hint: 'اختر الدور...',
      value: draft.roleId,
      items: {for (final r in state.rolesByDepartment) r.id: r.name},
      onChanged: (v) => bloc.add(StageRoleChanged(draft.stage.id, v)),
    );
  }
}

// ════════════════════════ dynamic fields (per-type multi-select) ════════════════════════

/// (FieldType, backend widget_type, Arabic title) for each dynamic field type.
const _dynTypes = <(FieldType, String, String)>[
  (FieldType.textField, 'text_field', 'حقل نص'),
  (FieldType.textDropdown, 'dropdown', 'قائمة منسدلة'),
  (FieldType.radioGroup, 'radio_group', 'اختيار من متعدد'),
  (FieldType.checkList, 'check_list', 'قائمة تحقق'),
  (FieldType.datePicker, 'date_picker', 'منتقي تاريخ'),
  (FieldType.filePicker, 'file_picker', 'منتقي ملفات'),
];

List<WidgetConfig> _libraryFrom(FieldsState f) => [
      ...f.textFields.map(WidgetConfigMapper.fromTextField),
      ...f.textDropdowns.map(WidgetConfigMapper.fromTextDropdown),
      ...f.radioGroups.map(WidgetConfigMapper.fromRadioGroup),
      ...f.checkLists.map(WidgetConfigMapper.fromCheckList),
      ...f.datePickers.map(WidgetConfigMapper.fromDatePicker),
      ...f.filePickers.map(WidgetConfigMapper.fromFilePicker),
    ];

class _DynamicFieldsEditor extends StatelessWidget {
  final StageConfigDraft draft;
  const _DynamicFieldsEditor({required this.draft});

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
                draft: draft,
                fieldType: type,
                backendType: backendType,
                title: title,
                options:
                    library.where((w) => w.widgetType == backendType).toList(),
                loading: loading,
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
  final StageConfigDraft draft;
  final FieldType fieldType;
  final String backendType;
  final String title;
  final List<WidgetConfig> options;
  final bool loading;

  const _FieldTypeBlock({
    required this.draft,
    required this.fieldType,
    required this.backendType,
    required this.title,
    required this.options,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final selected =
        draft.widgets.where((w) => w.widgetType == backendType).toList();
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
                onToggle: (w, sel) =>
                    bloc.add(StageWidgetToggled(draft.stage.id, w, sel)),
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
                  onRemove: () => bloc
                      .add(StageWidgetToggled(draft.stage.id, w, false)),
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
        // A live copy so checkboxes reflect toggles while the menu stays open.
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

// ════════════════════════ SERVICE TASK editor ════════════════════════
class _ServiceTaskEditor extends StatelessWidget {
  final StageConfigDraft draft;
  const _ServiceTaskEditor({required this.draft});

  static const _actions = {
    'GENERATE_PDF': 'توليد مستند PDF',
    'SEND_EMAIL': 'إرسال بريد إلكتروني',
    'SEND_NOTIFICATION': 'إرسال إشعار',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final selected = draft.actions.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'مهمة نظام — تُنفَّذ تلقائياً. يمكنك اختيار إجراءات (اختياري).',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        const WizardLabel('الإجراءات التلقائية'),
        const SizedBox(height: 8),
        for (final entry in _actions.entries)
          _CheckRow(
            label: entry.value,
            checked: selected.contains(entry.key),
            onChanged: (v) =>
                bloc.add(StageActionToggled(draft.stage.id, entry.key, v)),
          ),
      ],
    );
  }
}

// ════════════════════════ small shared pieces ════════════════════════
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

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Checkbox(
              value: checked,
              activeColor: AppColors.primary,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final bool spinner;
  const _Hint(this.text, {this.spinner = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (spinner) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
