import 'package:equatable/equatable.dart';

/// A single row of `GET /api/process_definitions/admin/type/{id}` (id `0` = all
/// types) — the full catalogue of processes for the technical team's "all" tab.
class AdminProcessItem extends Equatable {
  final int processId;
  final String name;
  final String? code;
  final int? priority;

  /// Camunda deployment status (e.g. "deployed").
  final String? deploymentStatus;

  /// `approval_status` value (null | "PENDING" | "APPROVED" | "REJECTED").
  final String? approvalStatus;
  final bool isActive;

  const AdminProcessItem({
    required this.processId,
    required this.name,
    this.code,
    this.priority,
    this.deploymentStatus,
    this.approvalStatus,
    required this.isActive,
  });

  bool get isApproved => approvalStatus == 'APPROVED';

  @override
  List<Object?> get props => [
        processId,
        name,
        code,
        priority,
        deploymentStatus,
        approvalStatus,
        isActive,
      ];
}
