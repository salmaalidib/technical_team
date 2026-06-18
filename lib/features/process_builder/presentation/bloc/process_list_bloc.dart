import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/get_process_details_usecase.dart';
import '../../domain/usecases/get_processes_by_type_usecase.dart';
import '../../domain/usecases/get_review_queue_usecase.dart';
import 'process_list_event.dart';
import 'process_list_state.dart';

/// Read side of the process builder: the two listing tabs and the details view.
/// Kept separate from [ProcessBuilderBloc] (which owns the create wizard).
class ProcessListBloc extends Bloc<ProcessListEvent, ProcessListState> {
  final GetProcessesByTypeUseCase getProcessesByType;
  final GetReviewQueueUseCase getReviewQueue;
  final GetProcessDetailsUseCase getProcessDetails;

  ProcessListBloc({
    required this.getProcessesByType,
    required this.getReviewQueue,
    required this.getProcessDetails,
  }) : super(const ProcessListState()) {
    on<LoadAllProcesses>(_onLoadAll);
    on<LoadProcessesByType>(_onLoadByType);
    on<LoadReviewQueue>(_onLoadReview);
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
