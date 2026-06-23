import 'package:equatable/equatable.dart';

abstract class ProcessListEvent extends Equatable {
  const ProcessListEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the "all processes" tab (`admin/type/0`).
class LoadAllProcesses extends ProcessListEvent {
  const LoadAllProcesses();
}

/// Loads the processes of a single type (`admin/type/{typeId}`).
class LoadProcessesByType extends ProcessListEvent {
  final int typeId;

  const LoadProcessesByType(this.typeId);

  @override
  List<Object?> get props => [typeId];
}

/// Loads the "review queue" tab (`admin/review-queue`).
class LoadReviewQueue extends ProcessListEvent {
  const LoadReviewQueue();
}

/// Loads the "missing stage config" tab (`admin/missing-stage-config`).
class LoadMissingStageConfig extends ProcessListEvent {
  const LoadMissingStageConfig();
}

/// Approves (publishes) or rejects a process (`{id}/review`). On success the
/// review queue reloads so the decided item drops off.
class ReviewProcessRequested extends ProcessListEvent {
  final int id;
  final bool approve;
  const ReviewProcessRequested(this.id, {required this.approve});
  @override
  List<Object?> get props => [id, approve];
}

/// Loads the full details of a single process (`{id}/details`).
class LoadProcessDetails extends ProcessListEvent {
  final int id;

  const LoadProcessDetails(this.id);

  @override
  List<Object?> get props => [id];
}
