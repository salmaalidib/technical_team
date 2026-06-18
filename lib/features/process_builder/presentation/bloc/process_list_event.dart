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

/// Loads the full details of a single process (`{id}/details`).
class LoadProcessDetails extends ProcessListEvent {
  final int id;

  const LoadProcessDetails(this.id);

  @override
  List<Object?> get props => [id];
}
