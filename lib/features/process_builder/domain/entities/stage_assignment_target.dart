import 'package:equatable/equatable.dart';

/// One (organization, department, role) target of a USER_TASK stage.
///
/// The backend accepts an ARRAY of these per stage
/// (`stages[].assignments[] = { organization_id, department_id, role_id }`),
/// so a single stage can be handed to several dept/role targets at once and
/// every matching employee sees the task. [organizationId] is always the
/// user's active organization — it is seeded system-wide, not picked per
/// target — so only the department and role vary between entries.
///
/// An all-null triple is the citizen (transaction owner) assignment: the
/// backend resolves it to the CITIZEN role (see `stageConfigService.js` →
/// `getCitizenRole()`).
class StageAssignmentTarget extends Equatable {
  final int? organizationId;
  final int? departmentId;
  final int? roleId;

  /// Display names, kept only so the chips can be labelled without re-fetching
  /// the cascade for every department the user picked.
  final String departmentName;
  final String roleName;

  const StageAssignmentTarget({
    this.organizationId,
    this.departmentId,
    this.roleId,
    this.departmentName = '',
    this.roleName = '',
  });

  /// The citizen (transaction owner) assignment — an all-null triple.
  const StageAssignmentTarget.citizen()
      : organizationId = null,
        departmentId = null,
        roleId = null,
        departmentName = '',
        roleName = '';

  bool get isCitizen =>
      organizationId == null && departmentId == null && roleId == null;

  /// Identity used to prevent adding the same target twice.
  String get key => '$organizationId/$departmentId/$roleId';

  /// Chip label: `الدور — القسم` (falls back to ids when a name is missing,
  /// e.g. a draft restored without its cascade loaded). The organization is
  /// omitted: it is the same active organization for every target.
  String get label {
    if (isCitizen) return 'صاحب المعاملة (مواطن)';
    final parts = <String>[
      roleName.isNotEmpty ? roleName : 'دور #$roleId',
      if (departmentName.isNotEmpty) departmentName,
    ];
    return parts.join(' — ');
  }

  Map<String, dynamic> toJson() => {
        'organization_id': organizationId,
        'department_id': departmentId,
        'role_id': roleId,
      };

  @override
  List<Object?> get props => [organizationId, departmentId, roleId];
}
