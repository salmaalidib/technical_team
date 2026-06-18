import 'package:equatable/equatable.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/entities/admin_process_item.dart';
import '../../domain/entities/process_details.dart';
import '../../domain/entities/review_queue_item.dart';

class ProcessListState extends Equatable {
  /// "All processes" tab.
  final RequestStatus allStatus;
  final List<AdminProcessItem> allProcesses;
  final String? allError;

  /// "Review queue" tab.
  final RequestStatus reviewStatus;
  final List<ReviewQueueItem> reviewQueue;
  final String? reviewError;

  /// Single-process details load.
  final RequestStatus detailsStatus;
  final ProcessDetails? details;
  final String? detailsError;

  const ProcessListState({
    this.allStatus = RequestStatus.initial,
    this.allProcesses = const [],
    this.allError,
    this.reviewStatus = RequestStatus.initial,
    this.reviewQueue = const [],
    this.reviewError,
    this.detailsStatus = RequestStatus.initial,
    this.details,
    this.detailsError,
  });

  ProcessListState copyWith({
    RequestStatus? allStatus,
    List<AdminProcessItem>? allProcesses,
    String? allError,
    RequestStatus? reviewStatus,
    List<ReviewQueueItem>? reviewQueue,
    String? reviewError,
    RequestStatus? detailsStatus,
    ProcessDetails? details,
    String? detailsError,
  }) {
    return ProcessListState(
      allStatus: allStatus ?? this.allStatus,
      allProcesses: allProcesses ?? this.allProcesses,
      allError: allError,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewQueue: reviewQueue ?? this.reviewQueue,
      reviewError: reviewError,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      details: details ?? this.details,
      detailsError: detailsError,
    );
  }

  @override
  List<Object?> get props => [
        allStatus,
        allProcesses,
        allError,
        reviewStatus,
        reviewQueue,
        reviewError,
        detailsStatus,
        details,
        detailsError,
      ];
}
