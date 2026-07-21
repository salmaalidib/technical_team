import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/get_missing_stage_config_usecase.dart';
import '../../domain/usecases/get_process_details_usecase.dart';
import '../../domain/usecases/get_processes_by_type_usecase.dart';
import '../../domain/usecases/get_review_queue_usecase.dart';
import '../../domain/usecases/review_process_usecase.dart';
import 'process_list_event.dart';
import 'process_list_state.dart';

/// Read side of the process builder: the listing tabs, the details view, and
/// the approve/reject action. Kept separate from [ProcessBuilderBloc] (which
/// owns the create wizard).
class ProcessListBloc extends Bloc<ProcessListEvent, ProcessListState> {
  final GetProcessesByTypeUseCase getProcessesByType;
  final GetReviewQueueUseCase getReviewQueue;
  final GetProcessDetailsUseCase getProcessDetails;
  final GetMissingStageConfigUseCase getMissingStageConfig;
  final ReviewProcessUseCase reviewProcess;

  ProcessListBloc({
    required this.getProcessesByType,
    required this.getReviewQueue,
    required this.getProcessDetails,
    required this.getMissingStageConfig,
    required this.reviewProcess,
  }) : super(const ProcessListState()) {
    on<LoadAllProcesses>(_onLoadAll);
    on<LoadProcessesByType>(_onLoadByType);
    on<LoadReviewQueue>(_onLoadReview);
    on<LoadMissingStageConfig>(_onLoadMissing);
    on<ReviewProcessRequested>(_onReviewProcess);
    on<LoadProcessDetails>(_onLoadDetails);
  }

  Future<void> _onLoadAll(
    LoadAllProcesses event,
    Emitter<ProcessListState> emit,
  ) => _loadProcesses(0, emit);

  Future<void> _onLoadByType(
    LoadProcessesByType event,
    Emitter<ProcessListState> emit,
  ) => _loadProcesses(event.typeId, emit);

  Future<void> _loadProcesses(
    int typeId,
    Emitter<ProcessListState> emit,
  ) async {
    emit(state.copyWith(allStatus: RequestStatus.loading, allError: null));

    final result = await getProcessesByType(typeId: typeId);

    result.fold(
      (failure) => emit(state.copyWith(
        allStatus: RequestStatus.failure,
        allError: failure.message,
      )),
      (items) => emit(state.copyWith(
        allStatus: RequestStatus.success,
        allProcesses: items,
        allError: null,
      )),
    );
  }

  Future<void> _onLoadReview(
    LoadReviewQueue event,
    Emitter<ProcessListState> emit,
  ) async {
    emit(state.copyWith(
      reviewStatus: RequestStatus.loading,
      reviewError: null,
    ));

    final result = await getReviewQueue();

    result.fold(
      (failure) => emit(state.copyWith(
        reviewStatus: RequestStatus.failure,
        reviewError: failure.message,
      )),
      (items) => emit(state.copyWith(
        reviewStatus: RequestStatus.success,
        reviewQueue: items,
        reviewError: null,
      )),
    );
  }

  Future<void> _onLoadMissing(
    LoadMissingStageConfig event,
    Emitter<ProcessListState> emit,
  ) async {
    emit(state.copyWith(
      missingStatus: RequestStatus.loading,
      missingError: null,
    ));

    final result = await getMissingStageConfig();

    result.fold(
      (failure) => emit(state.copyWith(
        missingStatus: RequestStatus.failure,
        missingError: failure.message,
      )),
      (items) => emit(state.copyWith(
        missingStatus: RequestStatus.success,
        missingItems: items,
        missingError: null,
      )),
    );
  }

  Future<void> _onReviewProcess(
    ReviewProcessRequested event,
    Emitter<ProcessListState> emit,
  ) async {
    // Guard against a second decision while one is in flight.
    if (state.reviewActionStatus == RequestStatus.loading) return;

    emit(state.copyWith(
      reviewActionStatus: RequestStatus.loading,
      reviewActionId: event.id,
      reviewActionError: null,
      reviewActionSuccess: null,
    ));

    final result = await reviewProcess(
      id: event.id,
      decision: event.approve ? ReviewDecision.approve : ReviewDecision.reject,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        reviewActionStatus: RequestStatus.failure,
        reviewActionError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(
          reviewActionStatus: RequestStatus.success,
          reviewActionSuccess: event.approve
              ? 'تمت الموافقة على المعاملة ونشرها'
              : 'تم رفض المعاملة',
        ));
        // Refresh the server-side data so the decided item lands in its new
        // bucket (an approved item moves to the "inactive" tab, a rejected one
        // to the "rejected" tab) instead of just vanishing. Both the review
        // queue and the missing-config list are reloaded.
        add(const LoadReviewQueue());
        add(const LoadMissingStageConfig());
      },
    );
  }

  Future<void> _onLoadDetails(
    LoadProcessDetails event,
    Emitter<ProcessListState> emit,
  ) async {
    emit(state.copyWith(
      detailsStatus: RequestStatus.loading,
      detailsError: null,
    ));

    final result = await getProcessDetails(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        detailsStatus: RequestStatus.failure,
        detailsError: failure.message,
      )),
      (details) => emit(state.copyWith(
        detailsStatus: RequestStatus.success,
        details: details,
        detailsError: null,
      )),
    );
  }
}
