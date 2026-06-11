import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/field_type.dart';
import '../../domain/usecases/create_check_list_usecase.dart';
import '../../domain/usecases/create_date_picker_usecase.dart';
import '../../domain/usecases/create_file_picker_usecase.dart';
import '../../domain/usecases/create_radio_group_usecase.dart';
import '../../domain/usecases/create_text_dropdown_usecase.dart';
import '../../domain/usecases/create_text_field_usecase.dart';
import '../../domain/usecases/get_check_lists_usecase.dart';
import '../../domain/usecases/get_date_pickers_usecase.dart';
import '../../domain/usecases/get_file_pickers_usecase.dart';
import '../../domain/usecases/get_radio_groups_usecase.dart';
import '../../domain/usecases/get_text_dropdowns_usecase.dart';
import '../../domain/usecases/get_text_fields_usecase.dart';
import 'fields_event.dart';
import 'fields_state.dart';

class FieldsBloc extends Bloc<FieldsEvent, FieldsState> {
  final GetTextFieldsUseCase getTextFields;
  final GetRadioGroupsUseCase getRadioGroups;
  final GetTextDropdownsUseCase getTextDropdowns;
  final GetCheckListsUseCase getCheckLists;
  final GetDatePickersUseCase getDatePickers;
  final GetFilePickersUseCase getFilePickers;

  final CreateTextFieldUseCase createTextField;
  final CreateRadioGroupUseCase createRadioGroup;
  final CreateTextDropdownUseCase createTextDropdown;
  final CreateCheckListUseCase createCheckList;
  final CreateDatePickerUseCase createDatePicker;
  final CreateFilePickerUseCase createFilePicker;

  FieldsBloc({
    required this.getTextFields,
    required this.getRadioGroups,
    required this.getTextDropdowns,
    required this.getCheckLists,
    required this.getDatePickers,
    required this.getFilePickers,
    required this.createTextField,
    required this.createRadioGroup,
    required this.createTextDropdown,
    required this.createCheckList,
    required this.createDatePicker,
    required this.createFilePicker,
  }) : super(const FieldsState()) {
    on<LoadAllFields>(_onLoadAll);
    on<SelectFieldType>(_onSelect);
    on<CreateFieldRequested>(_onCreate);
  }

  Future<void> _onLoadAll(
    LoadAllFields event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(
      loadStatus: RequestStatus.loading,
      error: null,
      createStatus: FormStatus.idle,
      createError: null,
    ));

    // Start all 6 requests in parallel, then await each typed result.
    final tfFuture = getTextFields();
    final rgFuture = getRadioGroups();
    final tdFuture = getTextDropdowns();
    final clFuture = getCheckLists();
    final dpFuture = getDatePickers();
    final fpFuture = getFilePickers();

    final tfResult = await tfFuture;
    final rgResult = await rgFuture;
    final tdResult = await tdFuture;
    final clResult = await clFuture;
    final dpResult = await dpFuture;
    final fpResult = await fpFuture;

    // Surface the first failure if any request failed.
    final failure = [tfResult, rgResult, tdResult, clResult, dpResult, fpResult]
        .map((r) => r.fold((f) => f, (_) => null))
        .firstWhere((f) => f != null, orElse: () => null);

    if (failure != null) {
      emit(state.copyWith(
        loadStatus: RequestStatus.failure,
        error: failure.message,
      ));
      return;
    }

    emit(state.copyWith(
      loadStatus: RequestStatus.success,
      error: null,
      textFields: tfResult.getOrElse(() => state.textFields),
      radioGroups: rgResult.getOrElse(() => state.radioGroups),
      textDropdowns: tdResult.getOrElse(() => state.textDropdowns),
      checkLists: clResult.getOrElse(() => state.checkLists),
      datePickers: dpResult.getOrElse(() => state.datePickers),
      filePickers: fpResult.getOrElse(() => state.filePickers),
    ));
  }

  void _onSelect(SelectFieldType event, Emitter<FieldsState> emit) {
    emit(state.copyWith(selectedType: event.type));
  }

  Future<void> _onCreate(
    CreateFieldRequested event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(
      createStatus: FormStatus.submitting,
      createError: null,
    ));

    final result = switch (event.type) {
      FieldType.textField => await createTextField(event.body),
      FieldType.radioGroup => await createRadioGroup(event.body),
      FieldType.textDropdown => await createTextDropdown(event.body),
      FieldType.checkList => await createCheckList(event.body),
      FieldType.datePicker => await createDatePicker(event.body),
      FieldType.filePicker => await createFilePicker(event.body),
    };

    await result.fold(
      (failure) async => emit(state.copyWith(
        createStatus: FormStatus.failure,
        createError: failure.message,
      )),
      (_) async {
        // Refetch ONLY the type that changed (1 GET) instead of all 6.
        emit(state.copyWith(createStatus: FormStatus.success));
        await _reloadType(event.type, emit);
      },
    );
  }

  /// Refetches only the list for [type] (a single GET) and updates just that
  /// slice of state — instead of reloading all six lists after a create.
  Future<void> _reloadType(FieldType type, Emitter<FieldsState> emit) {
    return switch (type) {
      FieldType.textField =>
        _reload(getTextFields.call, (l) => state.copyWith(textFields: l), emit),
      FieldType.radioGroup => _reload(
          getRadioGroups.call, (l) => state.copyWith(radioGroups: l), emit),
      FieldType.textDropdown => _reload(
          getTextDropdowns.call, (l) => state.copyWith(textDropdowns: l), emit),
      FieldType.checkList =>
        _reload(getCheckLists.call, (l) => state.copyWith(checkLists: l), emit),
      FieldType.datePicker =>
        _reload(getDatePickers.call, (l) => state.copyWith(datePickers: l), emit),
      FieldType.filePicker =>
        _reload(getFilePickers.call, (l) => state.copyWith(filePickers: l), emit),
    };
  }

  /// Runs a single getter and, on success, emits the state produced by
  /// [withList]. A failed silent reload leaves the existing list untouched.
  Future<void> _reload<T>(
    Future<Either<Failure, List<T>>> Function() get,
    FieldsState Function(List<T> list) withList,
    Emitter<FieldsState> emit,
  ) async {
    (await get()).fold((_) {}, (list) => emit(withList(list)));
  }
}
