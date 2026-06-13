import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/create_type_process_usecase.dart';
import '../../domain/usecases/get_type_processes_usecase.dart';
import '../../domain/usecases/update_type_process_status_usecase.dart';
import 'type_processes_event.dart';
import 'type_processes_state.dart';

class TypeProcessesBloc
    extends Bloc<TypeProcessesEvent, TypeProcessesState> {
  final GetTypeProcessesUseCase getTypeProcesses;
  final CreateTypeProcessUseCase createTypeProcess;
  final UpdateTypeProcessStatusUseCase updateStatus;

  TypeProcessesBloc({
    required this.getTypeProcesses,
    required this.createTypeProcess,
    required this.updateStatus,
  }) : super(const TypeProcessesState()) {
    on<LoadTypeProcesses>(_onLoad);
    on<CreateTypeProcessRequested>(_onCreate);
    on<ToggleTypeProcessStatus>(_onToggle);
  }

  Future<void> _onLoad(
    LoadTypeProcesses event,
    Emitter<TypeProcessesState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final result = await getTypeProcesses();

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: RequestStatus.success,
        typeProcesses: items,
        error: null,
      )),
    );
  }

  Future<void> _onCreate(
    CreateTypeProcessRequested event,
    Emitter<TypeProcessesState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createTypeProcess(name: event.name, code: event.code);

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadTypeProcesses());
      },
    );
  }

  Future<void> _onToggle(
    ToggleTypeProcessStatus event,
    Emitter<TypeProcessesState> emit,
  ) async {
    emit(state.copyWith(
      togglingIds: {...state.togglingIds, event.id},
      actionError: null,
    ));

    final result = await updateStatus(id: event.id, isActive: event.isActive);

    final toggling = {...state.togglingIds}..remove(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        togglingIds: toggling,
        actionError: failure.message,
      )),
      (updated) {
        final items = state.typeProcesses
            .map((t) =>
                t.id == updated.id ? t.copyWith(isActive: updated.isActive) : t)
            .toList();

        emit(state.copyWith(
          typeProcesses: items,
          togglingIds: toggling,
        ));
      },
    );
  }
}
