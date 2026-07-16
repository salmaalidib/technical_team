import '../../domain/entities/process_details.dart';

class ProcessDetailsModel extends ProcessDetails {
  const ProcessDetailsModel({
    required super.process,
    super.stages,
    required super.validation,
  });

  /// Parses the `data` envelope of `GET /api/process_definitions/{id}/details`:
  /// `{ process, stages, validation }`.
  factory ProcessDetailsModel.fromJson(Map<String, dynamic> data) {
    final rawStages = (data['stages'] ?? const []) as List;
    final rawValidation = (data['validation'] ?? const {}) as Map;

    return ProcessDetailsModel(
      process: _info((data['process'] ?? const {}) as Map),
      stages: rawStages
          .map<ProcessDetailStage>((e) => _stage(e as Map))
          .toList(),
      validation: _validation(rawValidation),
    );
  }

  static ProcessInfo _info(Map p) {
    return ProcessInfo(
      id: (p['id'] as num).toInt(),
      name: (p['name'] ?? '') as String,
      code: p['code'] as String?,
      status: p['status'] as String?,
      version: (p['version'] as num?)?.toInt(),
      isActive: p['is_active'] == true,
      approvalStatus: p['approval_status'] as String?,
      isApproved: p['is_approved'] == true,
      startDate: p['start_date'] as String?,
      endDate: p['end_date'] as String?,
    );
  }

  static ProcessDetailStage _stage(Map s) {
    final rawAssignments = (s['assignments'] ?? const []) as List;
    return ProcessDetailStage(
      id: (s['id'] as num).toInt(),
      name: (s['name'] ?? '') as String,
      code: s['code'] as String?,
      type: s['type'] as String?,
      authType: s['auth_type'] as String?,
      hasConfig: s['has_config'] == true,
      config: s['config'] is Map
          ? Map<String, dynamic>.from(s['config'] as Map)
          : null,
      hasAssignments: s['has_assignments'] == true,
      assignments: rawAssignments
          .map<StageAssignment>((e) => _assignment(e as Map))
          .toList(),
    );
  }

  static StageAssignment _assignment(Map a) {
    final rawRole = a['role'];
    return StageAssignment(
      organizationDepartmentRolesId:
          (a['organization_department_roles_id'] as num).toInt(),
      role: rawRole is Map ? _role(rawRole) : null,
    );
  }

  static AssignmentRole _role(Map r) {
    return AssignmentRole(
      id: (r['id'] as num).toInt(),
      isActive: r['is_active'] == true,
      department: _nameOf(r['department']),
      organization: _nameOf(r['organization']),
    );
  }

  /// The backend returns `organization`/`department` either as a plain name
  /// string or as an object `{ name: ... }` (or null). Normalize all three to
  /// the name string.
  static String? _nameOf(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['name'] as String?;
    return null;
  }

  static ProcessValidation _validation(Map v) {
    final rawErrors = (v['errors'] ?? const []) as List;
    return ProcessValidation(
      isValid: v['is_valid'] == true,
      errors: rawErrors.map((e) => e.toString()).toList(),
    );
  }
}
