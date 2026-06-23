import 'package:equatable/equatable.dart';

/// One item of `GET /api/process_definitions/admin/missing-stage-config`: a
/// process that has no stages, or at least one stage without a `stage_config`.
/// The technical team opens it in the wizard (step 4) to finish configuring it.
class MissingConfigItem extends Equatable {
  final int id;
  final String name;
  final String? status; // approval_status: PENDING | APPROVED | REJECTED
  final bool isApproved;
  final bool isActive;

  /// Total stages and how many still lack a `stage_config`.
  final int stagesTotalCount;
  final int stagesMissingConfigCount;

  const MissingConfigItem({
    required this.id,
    required this.name,
    this.status,
    required this.isApproved,
    required this.isActive,
    required this.stagesTotalCount,
    required this.stagesMissingConfigCount,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        isApproved,
        isActive,
        stagesTotalCount,
        stagesMissingConfigCount,
      ];
}
