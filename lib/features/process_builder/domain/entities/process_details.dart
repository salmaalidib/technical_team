import 'package:equatable/equatable.dart';

/// Full process payload of `GET /api/process_definitions/{id}/details`:
/// the process, its stages (each with config + role assignments) and a
/// validation verdict describing whether the setup is complete.
class ProcessDetails extends Equatable {
  final ProcessInfo process;
  final List<ProcessDetailStage> stages;
  final ProcessValidation validation;

  const ProcessDetails({
    required this.process,
    this.stages = const [],
    required this.validation,
  });

  @override
  List<Object?> get props => [process, stages, validation];
}

class ProcessInfo extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? status; // deployment status, e.g. "deployed"
  final int? version;
  final bool isActive;
  final String? approvalStatus;
  final bool isApproved;
  final String? startDate;
  final String? endDate;

  const ProcessInfo({
    required this.id,
    required this.name,
    this.code,
    this.status,
    this.version,
    required this.isActive,
    this.approvalStatus,
    required this.isApproved,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        status,
        version,
        isActive,
        approvalStatus,
        isApproved,
        startDate,
        endDate,
      ];
}

class ProcessDetailStage extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? type; // USER_TASK | SERVICE_TASK
  final String? authType; // AUTH | null
  final bool hasConfig;
  final Map<String, dynamic>? config;
  final bool hasAssignments;
  final List<StageAssignment> assignments;

  const ProcessDetailStage({
    required this.id,
    required this.name,
    this.code,
    this.type,
    this.authType,
    required this.hasConfig,
    this.config,
    required this.hasAssignments,
    this.assignments = const [],
  });

  bool get isUserTask => type == 'USER_TASK';
  bool get isServiceTask => type == 'SERVICE_TASK';
  bool get isAuth => authType == 'AUTH';

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        type,
        authType,
        hasConfig,
        config,
        hasAssignments,
        assignments,
      ];
}

class StageAssignment extends Equatable {
  final int organizationDepartmentRolesId;
  final AssignmentRole? role;

  const StageAssignment({
    required this.organizationDepartmentRolesId,
    this.role,
  });

  @override
  List<Object?> get props => [organizationDepartmentRolesId, role];
}

class AssignmentRole extends Equatable {
  final int id;
  final bool isActive;
  final String? department;
  final String? organization;

  const AssignmentRole({
    required this.id,
    required this.isActive,
    this.department,
    this.organization,
  });

  @override
  List<Object?> get props => [id, isActive, department, organization];
}

class ProcessValidation extends Equatable {
  final bool isValid;
  final List<String> errors;

  const ProcessValidation({
    required this.isValid,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [isValid, errors];
}
