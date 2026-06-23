import 'package:equatable/equatable.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/entities/admin_process_item.dart';
import '../../domain/entities/missing_config_item.dart';
import '../../domain/entities/process_details.dart';
import '../../domain/entities/review_queue_item.dart';

class ProcessListState extends Equatable {
  /// "All processes" tab.
  final RequestStatus allStatus;
  final List<AdminProcessItem> allProcesses;
  final String? allError;

  /// "Review queue" tab (completed processes awaiting approval).
  final RequestStatus reviewStatus;
  final List<ReviewQueueItem> reviewQueue;
  final String? reviewError;

  /// "Missing stage config" tab (incomplete processes).
  final RequestStatus missingStatus;
  final List<MissingConfigItem> missingItems;
  final String? missingError;

  /// Approve/reject action (`{id}/review`).
  final RequestStatus reviewActionStatus;
  final int? reviewActionId; // the process currently being approved/rejected
  final String? reviewActionError; // one-shot
  final String? reviewActionSuccess; // one-shot

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
    this.missingStatus = RequestStatus.initial,
    this.missingItems = const [],
    this.missingError,
    this.reviewActionStatus = RequestStatus.initial,
    this.reviewActionId,
    this.reviewActionError,
    this.reviewActionSuccess,
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
    RequestStatus? missingStatus,
    List<MissingConfigItem>? missingItems,
    String? missingError,
    RequestStatus? reviewActionStatus,
    int? reviewActionId,
    String? reviewActionError,
    String? reviewActionSuccess,
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
      missingStatus: missingStatus ?? this.missingStatus,
      missingItems: missingItems ?? this.missingItems,
      missingError: missingError,
      reviewActionStatus: reviewActionStatus ?? this.reviewActionStatus,
      reviewActionId: reviewActionId,
      reviewActionError: reviewActionError,
      reviewActionSuccess: reviewActionSuccess,
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
        missingStatus,
        missingItems,
        missingError,
        reviewActionStatus,
        reviewActionId,
        reviewActionError,
        reviewActionSuccess,
        detailsStatus,
        details,
        detailsError,
      ];
}
