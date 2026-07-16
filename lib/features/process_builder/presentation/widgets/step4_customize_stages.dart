import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/searchable_field_dropdown.dart';
import '../../../fields/domain/entities/field_type.dart';
import '../../domain/entities/notification_action_config.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
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
              child: draft!.locked
                  ? const _LockedStageNotice()
                  : (stage.isUserTask
                      ? _UserTaskEditor(state: state, draft: draft!)
                      : _ServiceTaskEditor(state: state, draft: draft!)),
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
    if (draft?.locked == true) {
      return stage.isUserTask
          ? 'مهمة مستخدم · مُهيّأة مسبقاً'
          : 'مهمة نظام · مُهيّأة مسبقاً';
    }
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
          if (draft?.locked == true) ...[
            const Icon(Icons.lock_outline_rounded,
                size: 18, color: AppColors.secondary),
            const SizedBox(width: 6),
          ],
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

/// Read-only panel shown for a stage that already has a saved `stage_config`
/// (complete-mode). It is not editable and is not re-submitted.
class _LockedStageNotice extends StatelessWidget {
  const _LockedStageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'هذه المرحلة مُهيّأة مسبقاً ولا يمكن تعديلها من هنا. '
              'احفظ لإكمال المراحل الناقصة فقط.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
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
    final isEmployee = draft.assigneeType == AssigneeType.employee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Who executes the stage: a specific employee (org/dept/role cascade)
        // or the transaction owner (citizen — a fixed role, no cascade).
        const WizardLabel('التعيين — من ينفّذ المرحلة *'),
        const SizedBox(height: 8),
        _AssigneeToggle(
          assigneeType: draft.assigneeType,
          onChanged: (t) => bloc.add(StageAssigneeTypeChanged(stageId, t)),
        ),
        const SizedBox(height: 12),
        // Employee → dept/role cascade. Organization is the user's active one,
        // seeded into the draft — no per-stage picker.
        if (isEmployee) ...[
          const _MiniLabel('القسم / الدائرة'),
          const SizedBox(height: 6),
          _DepartmentDropdown(state: state, draft: draft),
          const SizedBox(height: 12),
          const _MiniLabel('الدور'),
          const SizedBox(height: 6),
          _RoleDropdown(state: state, draft: draft),
        ] else
          const Text(
            'ستُسند هذه المرحلة إلى صاحب المعاملة (المواطن).',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        const SizedBox(height: 22),

        // dynamic fields — one multi-select dropdown per type + add button
        const WizardLabel('الحقول الديناميكية'),
        const SizedBox(height: 12),
        _DynamicFieldsEditor(draft: draft),
        const SizedBox(height: 20),

        // linked document templates — feed run-time PDF generation
        const WizardLabel('قوالب الوثائق'),
        const SizedBox(height: 6),
        const Text(
          'القوالب المرتبطة بهذه المرحلة — تُملأ بياناتها وقت التنفيذ، '
          'ويمكن توليدها PDF في مرحلة نظام لاحقة.',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _TemplatePicker(state: state, draft: draft),
      ],
    );
  }
}

/// Toggle for the USER_TASK assignee: a specific employee (org/dept/role
/// cascade) vs the transaction owner (citizen). Mirrors [_RecipientToggle].
class _AssigneeToggle extends StatelessWidget {
  final AssigneeType assigneeType;
  final ValueChanged<AssigneeType> onChanged;
  const _AssigneeToggle({required this.assigneeType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _RecipientChip(
            label: 'موظف (دور محدد)',
            selected: assigneeType == AssigneeType.employee,
            onTap: () => onChanged(AssigneeType.employee),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RecipientChip(
            label: 'صاحب المعاملة (مواطن)',
            selected: assigneeType == AssigneeType.citizen,
            onTap: () => onChanged(AssigneeType.citizen),
          ),
        ),
      ],
    );
  }
}

/// Multi-select for linking document templates to a USER_TASK stage. Mirrors
/// the dynamic-fields picker: a popup checkbox list + chips for the selected.
class _TemplatePicker extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _TemplatePicker({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final all = state.templates;
    final selectedIds = draft.templateIds.toSet();
    final selected =
        all.where((t) => selectedIds.contains(t.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopupMenuButton<void>(
          tooltip: 'اختر القوالب',
          enabled: all.isNotEmpty,
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
                    if (all.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد قوالب — أنشئ قوالب من صفحة القوالب',
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
                            for (final t in all)
                              InkWell(
                                onTap: () {
                                  final nowSelected =
                                      !localSelected.contains(t.id);
                                  if (nowSelected) {
                                    localSelected.add(t.id);
                                  } else {
                                    localSelected.remove(t.id);
                                  }
                                  bloc.add(StageTemplateToggled(
                                      draft.stage.id, t.id, nowSelected));
                                  setLocal(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Checkbox(
                                        value: localSelected.contains(t.id),
                                        activeColor: AppColors.primary,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (v) {
                                          final sel = v ?? false;
                                          if (sel) {
                                            localSelected.add(t.id);
                                          } else {
                                            localSelected.remove(t.id);
                                          }
                                          bloc.add(StageTemplateToggled(
                                              draft.stage.id, t.id, sel));
                                          setLocal(() {});
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          t.name,
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
                    all.isEmpty
                        ? 'لا توجد قوالب'
                        : (selected.isEmpty
                            ? 'اختر القوالب...'
                            : '${selected.length} قالب محدد'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: selected.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          selected.isEmpty ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final t in selected)
                _SelectedChip(
                  label: t.name,
                  onRemove: () => bloc.add(
                      StageTemplateToggled(draft.stage.id, t.id, false)),
                ),
            ],
          ),
        ],
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

/// One searchable, paginated multi-select dropdown per field type. Each block
/// keeps the selected widgets as chips below its dropdown.
class _DynamicFieldsEditor extends StatelessWidget {
  final StageConfigDraft draft;
  const _DynamicFieldsEditor({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (type, backendType, title) in _dynTypes) ...[
          _FieldTypeBlock(
            draft: draft,
            fieldType: type,
            backendType: backendType,
            title: title,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _FieldTypeBlock extends StatelessWidget {
  final StageConfigDraft draft;
  final FieldType fieldType;
  final String backendType;
  final String title;

  const _FieldTypeBlock({
    required this.draft,
    required this.fieldType,
    required this.backendType,
    required this.title,
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
        SearchableFieldDropdown(
          type: fieldType,
          title: title,
          mode: FieldDropdownMode.multi,
          selectedIds: selectedIds,
          onToggle: (w, sel) =>
              bloc.add(StageWidgetToggled(draft.stage.id, w, sel)),
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
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _ServiceTaskEditor({required this.state, required this.draft});

  // SEND_EMAIL is not supported by the backend (only SEND_NOTIFICATION and
  // GENERATE_PDF are accepted), so it is not offered here.
  static const _actions = {
    'GENERATE_PDF': 'توليد مستند PDF',
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
        for (final entry in _actions.entries) ...[
          _CheckRow(
            label: entry.value,
            checked: selected.contains(entry.key),
            onChanged: (v) =>
                bloc.add(StageActionToggled(draft.stage.id, entry.key, v)),
          ),
          // SEND_NOTIFICATION needs a message + recipient; show its inline
          // config right under its checkbox when selected.
          if (entry.key == 'SEND_NOTIFICATION' &&
              selected.contains('SEND_NOTIFICATION'))
            _NotificationConfigEditor(state: state, draft: draft),
          // GENERATE_PDF needs a template (linked in an earlier USER_TASK).
          if (entry.key == 'GENERATE_PDF' &&
              selected.contains('GENERATE_PDF'))
            _GeneratePdfConfigEditor(state: state, draft: draft),
        ],
      ],
    );
  }
}

/// Inline editor for the GENERATE_PDF payload: which linked template to render.
/// Only templates linked to an earlier USER_TASK stage are offered, so a
/// `document_instance` is guaranteed to exist at run-time.
class _GeneratePdfConfigEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _GeneratePdfConfigEditor({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final stageId = draft.stage.id;
    final linked = state.linkedTemplates;
    // Guard: if the chosen template was unlinked upstream, drop the stale value.
    final currentValue = linked.any((t) => t.id == draft.generatePdfTemplateId)
        ? draft.generatePdfTemplateId
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MiniLabel('القالب المُولَّد *'),
          const SizedBox(height: 6),
          if (linked.isEmpty)
            const _Hint(
                'اربط قالباً في مرحلة مستخدم سابقة أولاً، ثم اختره هنا.')
          else
            WizardDropdown<int>(
              hint: 'اختر القالب...',
              value: currentValue,
              items: {for (final t in linked) t.id: t.name},
              onChanged: (v) =>
                  bloc.add(StageGeneratePdfTemplateChanged(stageId, v)),
            ),
        ],
      ),
    );
  }
}

/// Inline editor for the SEND_NOTIFICATION payload: message + optional title +
/// recipient (citizen → AUTH, employee → org/dept/role cascade).
class _NotificationConfigEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _NotificationConfigEditor({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final stageId = draft.stage.id;
    final n = draft.notification;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MiniLabel('نص الإشعار *'),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: n.message,
            textAlign: TextAlign.right,
            maxLines: 3,
            minLines: 2,
            maxLength: 2000,
            decoration: _fieldDecoration('اكتب نص الإشعار...'),
            onChanged: (v) =>
                bloc.add(StageNotificationMessageChanged(stageId, v)),
          ),
          const SizedBox(height: 4),
          const _MiniLabel('عنوان الإشعار (اختياري)'),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: n.title,
            textAlign: TextAlign.right,
            maxLength: 255,
            decoration: _fieldDecoration('عنوان الإشعار...'),
            onChanged: (v) =>
                bloc.add(StageNotificationTitleChanged(stageId, v)),
          ),
          const SizedBox(height: 8),
          const _MiniLabel('المُستلِم *'),
          const SizedBox(height: 6),
          _RecipientToggle(
            recipient: n.recipient,
            onChanged: (r) =>
                bloc.add(StageNotificationRecipientChanged(stageId, r)),
          ),
          if (n.recipient == NotificationRecipient.employee) ...[
            const SizedBox(height: 12),
            // Organization is the user's active one (seeded when the recipient
            // becomes an employee) — no picker here.
            const _MiniLabel('القسم / الدائرة'),
            const SizedBox(height: 6),
            _NotificationDeptDropdown(state: state, draft: draft),
            const SizedBox(height: 12),
            const _MiniLabel('الدور'),
            const SizedBox(height: 6),
            _NotificationRoleDropdown(state: state, draft: draft),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'سيُرسَل الإشعار إلى صاحب المعاملة (المواطن).',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  static InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      );
}

class _RecipientToggle extends StatelessWidget {
  final NotificationRecipient recipient;
  final ValueChanged<NotificationRecipient> onChanged;
  const _RecipientToggle({required this.recipient, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _RecipientChip(
            label: 'صاحب المعاملة (مواطن)',
            selected: recipient == NotificationRecipient.citizen,
            onTap: () => onChanged(NotificationRecipient.citizen),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RecipientChip(
            label: 'موظف (دور محدد)',
            selected: recipient == NotificationRecipient.employee,
            onTap: () => onChanged(NotificationRecipient.employee),
          ),
        ),
      ],
    );
  }
}

class _RecipientChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RecipientChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Department dropdown for the notification employee cascade. Reads/writes the
/// notification config and dispatches the notification cascade events.
class _NotificationDeptDropdown extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _NotificationDeptDropdown({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final n = draft.notification;
    if (n.organizationId == null) {
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
      value: n.departmentId,
      items: {for (final d in state.leafDepartments) d.id: d.name},
      onChanged: (v) =>
          bloc.add(StageNotificationDeptChanged(draft.stage.id, v)),
    );
  }
}

class _NotificationRoleDropdown extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _NotificationRoleDropdown({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final n = draft.notification;
    if (n.departmentId == null) {
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
      value: n.roleId,
      items: {for (final r in state.rolesByDepartment) r.id: r.name},
      onChanged: (v) =>
          bloc.add(StageNotificationRoleChanged(draft.stage.id, v)),
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
