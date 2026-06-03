import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/get_fields_usecase.dart';
import '../../domain/usecases/save_field_usecase.dart';
import 'fields_event.dart';
import 'fields_state.dart';

class FieldsBloc extends Bloc<FieldsEvent, FieldsState> {
  final GetFieldsUseCase getFields;
  final SaveFieldUseCase saveField;

  FieldsBloc({
    required this.getFields,
    required this.saveField,
  }) : super(const FieldsState()) {
    on<LoadFields>(_onLoad);
    on<SaveFieldRequested>(_onSave);
  }

  Future<void> _onLoad(LoadFields event, Emitter<FieldsState> emit) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final result = await getFields();

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (fields) => emit(state.copyWith(
        status: RequestStatus.success,
        fields: fields,
        error: null,
      )),
    );
  }

  Future<void> _onSave(
    SaveFieldRequested event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await saveField(
      id: event.id,
      name: event.name,
      type: event.type,
      listValues: event.listValues,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadFields());
      },
    );
  }
}
