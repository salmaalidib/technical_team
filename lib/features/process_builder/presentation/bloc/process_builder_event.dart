import 'package:equatable/equatable.dart';

import '../../domain/entities/widget_config.dart';

abstract class ProcessBuilderEvent extends Equatable {
  const ProcessBuilderEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the data needed across the wizard: organizations, process types and
/// the field libraries (for "link fields"). [typeId] preselects the process
/// type when the wizard is opened from a type's processes page.
class InitWizard extends ProcessBuilderEvent {
  final int? typeId;

  const InitWizard({this.typeId});

  @override
  List<Object?> get props => [typeId];
}

class StepRequested extends ProcessBuilderEvent {
  final int step;
  const StepRequested(this.step);
  @override
  List<Object?> get props => [step];
}

// ── step 1: basic info ───────────────────────────────────────────────────────
class NameChanged extends ProcessBuilderEvent {
  final String name;
  const NameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class ComplaintChanged extends ProcessBuilderEvent {
  final bool isComplaint;
  const ComplaintChanged(this.isComplaint);
  @override
  List<Object?> get props => [isComplaint];
}

class TypeChanged extends ProcessBuilderEvent {
  final int? typeTransId;
  const TypeChanged(this.typeTransId);
  @override
  List<Object?> get props => [typeTransId];
}

class OrganizationChanged extends ProcessBuilderEvent {
  final int? organizationId;
  const OrganizationChanged(this.organizationId);
  @override
  List<Object?> get props => [organizationId];
}

class PriorityChanged extends ProcessBuilderEvent {
  final int priority;
  const PriorityChanged(this.priority);
  @override
  List<Object?> get props => [priority];
}

class StartDateChanged extends ProcessBuilderEvent {
  final DateTime date;
  const StartDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class EndDateChanged extends ProcessBuilderEvent {
  final DateTime? date;
  const EndDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

// ── step 2: upload BPMN ──────────────────────────────────────────────────────
class FileSelected extends ProcessBuilderEvent {
  final List<int> bytes;
  final String fileName;
  const FileSelected({required this.bytes, required this.fileName});
  @override
  List<Object?> get props => [fileName, bytes.length];
}

/// Calls `create` (step 2 → 3) and builds the stage drafts.
class SubmitCreate extends ProcessBuilderEvent {
  const SubmitCreate();
}

// ── step 4: customize stages ─────────────────────────────────────────────────
/// Expands a stage's inline editor card (or collapses it if already expanded).
class StageExpansionToggled extends ProcessBuilderEvent {
  final int stageId;
  const StageExpansionToggled(this.stageId);
  @override
  List<Object?> get props => [stageId];
}


class StageOrgChanged extends ProcessBuilderEvent {
  final int stageId;
  final int? organizationId;
  const StageOrgChanged(this.stageId, this.organizationId);
  @override
  List<Object?> get props => [stageId, organizationId];
}

class StageDeptChanged extends ProcessBuilderEvent {
  final int stageId;
  final int? departmentId;
  const StageDeptChanged(this.stageId, this.departmentId);
  @override
  List<Object?> get props => [stageId, departmentId];
}

class StageRoleChanged extends ProcessBuilderEvent {
  final int stageId;
  final int? roleId;
  const StageRoleChanged(this.stageId, this.roleId);
  @override
  List<Object?> get props => [stageId, roleId];
}

class StageWidgetToggled extends ProcessBuilderEvent {
  final int stageId;
  final WidgetConfig widget;
  final bool selected;
  const StageWidgetToggled(this.stageId, this.widget, this.selected);
  @override
  List<Object?> get props => [stageId, widget, selected];
}

class StageSignatureToggled extends ProcessBuilderEvent {
  final int stageId;
  final bool value;
  const StageSignatureToggled(this.stageId, this.value);
  @override
  List<Object?> get props => [stageId, value];
}

class StageActionToggled extends ProcessBuilderEvent {
  final int stageId;
  final String action;
  final bool selected;
  const StageActionToggled(this.stageId, this.action, this.selected);
  @override
  List<Object?> get props => [stageId, action, selected];
}

/// Final action: `POST /api/stage_config/create` only (no review/approve).
class SubmitStageConfigs extends ProcessBuilderEvent {
  const SubmitStageConfigs();
}
