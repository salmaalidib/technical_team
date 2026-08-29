import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/searchable_field_dropdown.dart';
import '../../../../shared/widgets/searchable_template_dropdown.dart';
import '../../../fields/domain/entities/field_type.dart';
import '../../domain/entities/notification_action_config.dart';
import '../../domain/entities/process_stage.dart';
import '../../domain/entities/stage_config_draft.dart';
import '../../domain/entities/sync_self_card_config.dart';
import '../../domain/entities/widget_config.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_event.dart';
import '../bloc/process_builder_state.dart';
import 'wizard_kit.dart';
import '../../../../shared/theme/app_dimens.dart';

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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: expanded ? AppColors.primary : AppColors.border,
          width: expanded ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
      if (!ready) return 'مهمة مستخدم · غير مُهيّأة';
      // A stage may be assigned to several org/dept/role targets at once; show
      // how many so the count is visible without expanding the card.
      final count = draft?.assignments.length ?? 0;
      if (draft?.assigneeType == AssigneeType.citizen) {
        return 'مهمة مستخدم · صاحب المعاملة';
      }
      // Dynamic routing is an extra property of the stage, not a replacement
      // for its targets — show both.
      if (draft?.isAssignment == true) {
        return 'مهمة مستخدم · $count جهة معيَّنة · توجيه ديناميكي';
      }
      return 'مهمة مستخدم · $count جهة معيَّنة';
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
              color:
                  expanded ? AppColors.primary : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(
              isUser ? Icons.shield_outlined : Icons.bolt_outlined,
              color: expanded ? AppColors.white : accent,
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
                        stage.displayName,
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
                // سطر واحد ثابت: الملخّص يطول ويقصر مع التعديلات، ولو التفّ
                // إلى سطرين لتغيّر ارتفاع الترويسة فتقفز البطاقة.
                Text(
                  _subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
        // Who executes the stage: specific employee roles (one or more
        // org/dept/role targets) or the transaction owner (citizen — a fixed
        // role, no cascade).
        const WizardLabel('التعيين — من ينفّذ المرحلة *'),
        const SizedBox(height: 8),
        _AssigneeToggle(
          assigneeType: draft.assigneeType,
          onChanged: (t) => bloc.add(StageAssigneeTypeChanged(stageId, t)),
        ),
        const SizedBox(height: 12),
        // Employee → an org/dept/role picker that can be used repeatedly; the
        // backend takes an array of assignments, so the stage can go to several
        // roles at once (different organizations and departments included).
        if (isEmployee)
          _AssignmentsEditor(state: state, draft: draft)
        else
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

        // gateway field — routes the BPMN flow in Camunda, kept separate and
        // called out explicitly (see _GatewayFieldSection docs below).
        const WizardLabel('حقل التوجيه (Exclusive Gateway)'),
        const SizedBox(height: 12),
        _GatewayFieldSection(draft: draft),
        const SizedBox(height: 20),

        // self card (employee_picker) — selects WHICH HR file a later
        // SYNC_SELF_CARD writes to. Kept out of the dynamic fields above
        // because it is not a field-library entry (see _SelfCardSection).
        const WizardLabel('البطاقة الذاتية'),
        const SizedBox(height: 12),
        _SelfCardSection(draft: draft),
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
        const SizedBox(height: 20),
        _IsAssignmentToggle(state: state, draft: draft),
      ],
    );
  }
}

/// Switch for `config_json.is_assignment`. Off by default (sent as `false`).
/// Turning it ON is confirmed via a dialog first, because it overrides the
/// fixed org/dept/role assignment above: the next stage will instead go to
/// whoever the CURRENT stage's assignees choose at run-time.
class _IsAssignmentToggle extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _IsAssignmentToggle({required this.state, required this.draft});

  Future<void> _handleChanged(BuildContext context, bool value) async {
    final bloc = context.read<ProcessBuilderBloc>();

    if (!value) {
      bloc.add(StageIsAssignmentToggled(draft.stage.id, false));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تنبيه هام قبل التفعيل',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          'تفعيل هذا الخيار سيُلغي التوجيه التلقائي للمرحلة القادمة إلى '
          'الموظفين المحدَّدين مسبقاً (المؤسسة/القسم/الدور).\n\n'
          'بدلاً من ذلك، سيصبح موظفو هذه المرحلة (أصحاب هذه الخطوة) هم من '
          'يحدّدون يدوياً إلى أي جهة تذهب المرحلة القادمة، وذلك وقت تنفيذهم '
          'للمعاملة.\n\n'
          'ملاحظة: هذا لا يغيّر من ينفّذ هذه المرحلة — يجب أن تبقى الجهات '
          'المُعيَّنة أعلاه محدَّدة، فهي من ستستلم المرحلة وتختار الوجهة.\n\n'
          'هل أنت متأكد من رغبتك في المتابعة؟',
          textAlign: TextAlign.right,
          style: TextStyle(height: 1.6, fontSize: 13.5),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('نعم، تفعيل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(StageIsAssignmentToggled(draft.stage.id, true));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only employees can route the next stage, so the backend rejects
    // is_assignment on a citizen-assigned stage. Disable it rather than let the
    // whole batch 400 at save time.
    final enabled = draft.assigneeType == AssigneeType.employee;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعيين ديناميكي — يُحدَّد لاحقاً من هذه المرحلة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // النصّان يختلفان في الطول (ثلاثة أسطر مقابل سطرين)، فتبديل
                // المفتاح كان يغيّر ارتفاع الكتلة ويقفز بما تحتها. نحجز
                // ارتفاع ثلاثة أسطر ثابتاً فلا يتحرّك شيء عند التبديل.
                SizedBox(
                  height: 54,
                  child: Text(
                    enabled
                        ? 'عند التفعيل: موظفو هذه المرحلة هم من يختارون وجهة '
                            'المرحلة القادمة، بدل التوجيه التلقائي. لا يغيّر ذلك '
                            'الجهات المُعيَّنة لتنفيذ هذه المرحلة.'
                        : 'غير متاح مع «صاحب المعاملة» — توجيه المرحلة القادمة '
                            'يقوم به موظف، لا المواطن.',
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: draft.isAssignment,
            activeColor: AppColors.error,
            onChanged: enabled ? (v) => _handleChanged(context, v) : null,
          ),
        ],
      ),
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

/// Links document templates to a USER_TASK stage.
///
/// Uses [SearchableTemplateDropdown] so it behaves exactly like the dynamic
/// field pickers above it: a search box with server-side filtering and a
/// lazily-paginated list, instead of a single popup holding every template.
///
/// Selection lives in the stage draft (not in `TemplatesBloc`), and the chips
/// read from `state.templates` — loaded in full at wizard boot — so a template
/// already linked to the stage still renders even when it is not on the page
/// the dropdown currently shows.
class _TemplatePicker extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _TemplatePicker({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final selectedIds = draft.templateIds.toSet();
    final selected =
        state.templates.where((t) => selectedIds.contains(t.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchableTemplateDropdown(
          selectedIds: selectedIds,
          selectedTemplates: selected,
          onToggle: (template, isSelected) => bloc.add(
            StageTemplateToggled(draft.stage.id, template.id, isSelected),
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
                  onRemove: () => bloc
                      .add(StageTemplateToggled(draft.stage.id, t.id, false)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Multi-target assignment editor for a USER_TASK.
///
/// The backend takes `stages[].assignments` as an ARRAY of
/// `{ organization_id, department_id, role_id }`, creating one
/// `stage_assignments` row per entry — so a stage can be handed to several
/// dept/role targets at once and every matching employee sees the task.
///
/// The organization defaults to the user's active one (see
/// `ActiveOrganizationCubit`) but is editable per stage, so a stage can be
/// handed to a department in another organization. Its options come from the
/// `GET /api/organization` list already loaded at wizard boot.
///
/// The org/dept/role dropdowns below are a PICKER: what they hold is not saved
/// until «إضافة التعيين» commits it as a chip. Only the committed chips are
/// submitted.
class _AssignmentsEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _AssignmentsEditor({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final stageId = draft.stage.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'يمكنك إسناد المرحلة إلى أكثر من جهة: اختر القسم والدور ثم اضغط '
          '«إضافة التعيين»، وكرّر ذلك لكل جهة تريدها.',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const _MiniLabel('المؤسسة'),
        const SizedBox(height: 6),
        _OrganizationDropdown(state: state, draft: draft),
        const SizedBox(height: 12),
        const _MiniLabel('القسم / الدائرة'),
        const SizedBox(height: 6),
        _DepartmentDropdown(state: state, draft: draft),
        const SizedBox(height: 12),
        const _MiniLabel('الدور'),
        const SizedBox(height: 6),
        _RoleDropdown(state: state, draft: draft),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: draft.canAddAssignment
                ? () => bloc.add(StageAssignmentAdded(stageId))
                : null,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('إضافة التعيين'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MiniLabel('الجهات المُعيَّنة  (${draft.assignments.length})'),
        const SizedBox(height: 6),
        if (draft.assignments.isEmpty)
          const _Hint('لم تُضف أي جهة بعد — أضف جهة واحدة على الأقل')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final a in draft.assignments)
                _SelectedChip(
                  label: a.label,
                  onRemove: () => bloc.add(StageAssignmentRemoved(stageId, a)),
                ),
            ],
          ),
      ],
    );
  }
}

/// Per-stage organization picker, fed by the `GET /api/organization` list
/// fetched once at wizard boot into `state.organizations`. Changing it clears
/// the department and role (the bloc reloads the new org's leaves), so the
/// cascade below always matches the organization shown here.
class _OrganizationDropdown extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _OrganizationDropdown({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    if (state.bootStatus == RequestStatus.loading) {
      return const _Hint('جاري تحميل المؤسسات...', spinner: true);
    }
    if (state.organizations.isEmpty) {
      return const _Hint('لا توجد مؤسسات');
    }
    return WizardDropdown<int>(
      hint: 'اختر المؤسسة...',
      searchHint: 'ابحث في المؤسسات...',
      value: draft.organizationId,
      items: {for (final o in state.organizations) o.id: o.name},
      onChanged: (v) => bloc.add(StageOrgChanged(draft.stage.id, v)),
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
      searchHint: 'ابحث في الأقسام...',
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
      searchHint: 'ابحث في الأدوار...',
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
  (FieldType.textDropdown, 'dropdown', 'قائمة اختيار وحيد'),
  (FieldType.checkList, 'check_list', 'قائمة اختيار من متعدد'),
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
                  onRemove: () =>
                      bloc.add(StageWidgetToggled(draft.stage.id, w, false)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ════════════════════════ gateway field (Camunda routing) ════════════════════════

/// The `radio_group` field is kept out of `_DynamicFieldsEditor` on purpose:
/// unlike every other dynamic field (display-only, filled and stored), a
/// `radio_group` marked as a gateway feeds `gateway_value` at submit time,
/// which becomes the Camunda process variable an Exclusive Gateway evaluates
/// to pick the next sequence flow. A wrong or missing option `key` here does
/// not just mis-render a form — it silently mis-routes the entire
/// transaction (approval sent down the rejection path, or the process
/// engine finding no matching flow and stalling the case indefinitely).
/// See `unifiedFormPayloadService.js` (findGatewayWidgetConfig /
/// buildCamundaGatewayVariables) on the backend for how this value is
/// consumed.
class _GatewayFieldSection extends StatelessWidget {
  final StageConfigDraft draft;
  const _GatewayFieldSection({required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final selected =
        draft.widgets.where((w) => w.widgetType == 'radio_group').toList();
    final selectedIds = selected.map((w) => w.widgetId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border:
                Border.all(color: AppColors.error.withOpacity(0.4), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه هام — هذا الحقل يتحكم في مسار المعاملة بالكامل',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.errorDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اختيار المستخدم هنا يُستخدم مباشرة لتحديد الفرع التالي في '
                      'مخطط سير العمل (Camunda). أي خطأ في مفاتيح الخيارات أو في '
                      'تحديد هذا الحقل كبوابة قد يوجّه المعاملة إلى مسار خاطئ '
                      'تماماً (مثال: موافقة تُرسَل كأنها رفض)، أو يجعل المعاملة '
                      'عالقة بلا مسار على الإطلاق دون أي إشعار بالخطأ. '
                      'تحقّق من الخيارات جيداً قبل الحفظ.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MiniLabel('حقل التوجيه (Exclusive Gateway)  (${selected.length})'),
        const SizedBox(height: 6),
        SearchableFieldDropdown(
          type: FieldType.radioGroup,
          title: 'حقل التوجيه (Exclusive Gateway)',
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
                  onRemove: () =>
                      bloc.add(StageWidgetToggled(draft.stage.id, w, false)),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════ self card (employee_picker) ════════════════════════

/// Toggle for the `employee_picker` widget — the picker that chooses WHICH
/// employee self card (`employee_self_cards.id`) a later `SYNC_SELF_CARD`
/// writes to.
///
/// It is deliberately NOT part of [_DynamicFieldsEditor]. Every widget there is
/// picked from the reusable field library, but the backend schema for this one
/// (`employeePickerDataSchema`) accepts exactly `{ id, label, is_required,
/// options_source }` and nothing else — its options are fetched at run-time
/// from `GET /api/self-cards/search`. There is no library entry to select, so
/// the widget is a fixed constant toggled on or off here.
///
/// `data.id` is pinned to `self_card_id` because a `SYNC_SELF_CARD` action
/// finds the card through `self_card_id_widget`, which references it by name.
class _SelfCardSection extends StatelessWidget {
  final StageConfigDraft draft;
  const _SelfCardSection({required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final enabled = draft.hasSelfCardPicker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أضف حقل اختيار البطاقة الذاتية إلى هذه المرحلة إذا كان الموظف '
          'سيحدّد الملف الوظيفي الذي ستُكتب عليه البيانات لاحقاً.',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _CheckRow(
          label: 'إضافة حقل «البطاقة الذاتية» لهذه المرحلة',
          checked: enabled,
          onChanged: (v) =>
              bloc.add(StageSelfCardPickerToggled(draft.stage.id, v)),
        ),
        if (enabled) ...[
          const SizedBox(height: 10),
          const _WarningBox(
            title: 'البطاقة الذاتية ليست حساب الموظف',
            body: 'هذا الحقل يختار «الملف الوظيفي» (البطاقة الذاتية) وليس '
                'حساب الدخول. ليس لكل مواطن بطاقة ذاتية، وقد لا يكون صاحب '
                'المعاملة هو صاحب البطاقة — يجب على الموظف اختيار البطاقة '
                'الصحيحة يدوياً وقت التنفيذ.\n\n'
                'ولن تُكتب أي بيانات على البطاقة بمجرد اختيارها: الكتابة تتم '
                'فقط عبر إجراء «تحديث البطاقة الذاتية» في مرحلة نظام لاحقة.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════ SERVICE TASK editor ════════════════════════
class _ServiceTaskEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _ServiceTaskEditor({required this.state, required this.draft});

  // SEND_EMAIL is not supported by the backend (only SEND_NOTIFICATION,
  // GENERATE_PDF and SYNC_SELF_CARD are accepted), so it is not offered here.
  static const _actions = {
    'GENERATE_PDF': 'توليد مستند PDF',
    'SEND_NOTIFICATION': 'إرسال إشعار',
    'SYNC_SELF_CARD': 'تحديث البطاقة الذاتية',
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
          if (entry.key == 'GENERATE_PDF' && selected.contains('GENERATE_PDF'))
            _GeneratePdfConfigEditor(state: state, draft: draft),
          // SYNC_SELF_CARD needs a target table + a non-empty field map.
          if (entry.key == 'SYNC_SELF_CARD' &&
              selected.contains('SYNC_SELF_CARD'))
            _SyncSelfCardConfigEditor(state: state, draft: draft),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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

/// Inline editor for the SYNC_SELF_CARD payload: which self-card table to
/// write to, and how each of its columns maps to a widget of an earlier
/// USER_TASK.
///
/// Two failure modes this editor exists to prevent:
///
/// 1. **A 400 on the whole batch.** The backend schema requires
///    `field_map` to have at least one entry (`.min(1).required()`), so an
///    enabled-but-unmapped action rejects every stage being saved, not just
///    this one.
/// 2. **A silent run-time no-op.** The sync reads a *sealed* snapshot of an
///    earlier USER_TASK, resolves the card from the `employee_picker` value,
///    and drops any column it does not recognise. A mapping that points at a
///    downstream widget, or a target with no upstream picker, therefore fails
///    (or writes nothing) only once a real transaction runs. Columns come from
///    a fixed per-target list and sources only from upstream stages so neither
///    can be expressed here.
class _SyncSelfCardConfigEditor extends StatelessWidget {
  final ProcessBuilderState state;
  final StageConfigDraft draft;
  const _SyncSelfCardConfigEditor({required this.state, required this.draft});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProcessBuilderBloc>();
    final stageId = draft.stage.id;
    final config = draft.syncSelfCard;
    final target = config.target;
    final sources = state.sourceWidgetsFor(stageId);
    final hasPicker = state.hasUpstreamSelfCardPicker(stageId);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blocking problem: without an upstream picker the action cannot
          // resolve a card and fails at run-time, long after saving.
          if (!hasPicker) ...[
            const _WarningBox(
              title: 'لا توجد بطاقة ذاتية في أي مرحلة سابقة',
              body: 'هذا الإجراء يحتاج إلى حقل «البطاقة الذاتية» في مرحلة '
                  'مستخدم سابقة ليعرف أي بطاقة سيحدّث. بدونه سيُحفظ الإعداد '
                  'بنجاح، لكنه سيفشل وقت تنفيذ المعاملة.\n\n'
                  'ارجع إلى مرحلة مستخدم سابقة وفعّل «إضافة حقل البطاقة '
                  'الذاتية».',
            ),
            const SizedBox(height: 12),
          ],
          const _MiniLabel('الجدول المُحدَّث *'),
          const SizedBox(height: 6),
          WizardDropdown<SelfCardTarget>(
            hint: 'اختر الجدول...',
            value: target,
            items: {
              for (final t in SelfCardTarget.values) t: t.label,
            },
            onChanged: (v) {
              if (v != null) bloc.add(StageSyncTargetChanged(stageId, v));
            },
          ),
          const SizedBox(height: 12),
          const _MiniLabel('ربط الحقول *'),
          const SizedBox(height: 4),
          const Text(
            'اختر لكل عمود الحقل الذي تُؤخذ منه قيمته من المرحلة السابقة. '
            'الأعمدة غير المربوطة لن تُكتب.',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (sources.isEmpty)
            const _Hint(
              'لا توجد حقول في المراحل السابقة — أضف حقولاً إلى مرحلة مستخدم '
              'قبل هذه المرحلة أولاً.',
            )
          else
            for (final column in target.columns) ...[
              _SyncFieldMapRow(
                column: column,
                label: target.labelFor(column),
                isRequired: target.requiredColumns.contains(column),
                sources: sources,
                selectedWidgetId: config.fieldMap[column],
                onChanged: (widgetId) =>
                    bloc.add(StageSyncFieldMapped(stageId, column, widgetId)),
              ),
              const SizedBox(height: 8),
            ],
          // Mirror of the backend rules, surfaced before the save is attempted.
          if (sources.isNotEmpty && !config.isComplete) ...[
            const SizedBox(height: 4),
            _WarningBox(
              title: 'الإعداد غير مكتمل',
              body: config.fieldMap.isEmpty
                  ? 'يجب ربط حقل واحد على الأقل، وإلا سيُرفض حفظ كل المراحل.'
                  : 'الحقول الإلزامية التالية غير مربوطة، وسيفشل التحديث وقت '
                      'التنفيذ: '
                      '${config.missingRequiredColumns.map(target.labelFor).join('، ')}.',
            ),
          ],
        ],
      ),
    );
  }
}

/// One `field_map` row: a fixed target column on the right, and the upstream
/// widget its value comes from on the left.
class _SyncFieldMapRow extends StatelessWidget {
  final String column;
  final String label;
  final bool isRequired;
  final List<WidgetConfig> sources;
  final String? selectedWidgetId;
  final ValueChanged<String?> onChanged;

  const _SyncFieldMapRow({
    required this.column,
    required this.label,
    required this.isRequired,
    required this.sources,
    required this.selectedWidgetId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // A source widget removed upstream must not keep a stale mapping alive.
    final value = sources.any((w) => w.widgetId == selectedWidgetId)
        ? selectedWidgetId
        : null;

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            isRequired ? '$label *' : label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isRequired ? FontWeight.w700 : FontWeight.w500,
              color: isRequired && value == null
                  ? AppColors.errorDark
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: WizardDropdown<String>(
            hint: 'بدون ربط',
            value: value,
            items: {for (final w in sources) w.widgetId: w.label},
            onChanged: onChanged,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
        fillColor: AppColors.white,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textPrimary,
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
      searchHint: 'ابحث في الأقسام...',
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
      searchHint: 'ابحث في الأدوار...',
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A prominent, high-contrast warning panel. Used for the cases where a
/// configuration saves cleanly but misbehaves later — a wrong self card, or a
/// SYNC_SELF_CARD that cannot resolve its card at run-time — so the risk is
/// visible at the moment of configuring rather than after a failed
/// transaction.
class _WarningBox extends StatelessWidget {
  final String title;
  final String body;
  const _WarningBox({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border:
            Border.all(color: AppColors.error.withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.errorDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
