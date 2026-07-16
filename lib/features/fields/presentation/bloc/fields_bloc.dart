import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../process_builder/data/mappers/widget_config_mapper.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
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

/// Page size requested from the backend for every dynamic-field dropdown.
const int kFieldsPageSize = 10;

/// Debounce window for the in-dropdown search box.
const Duration _kSearchDebounce = Duration(milliseconds: 350);

/// Restartable debounce: for each incoming event, wait [duration]; if a newer
/// event arrives first, the pending one is dropped. Implemented without any
/// extra package (no rxdart / stream_transform).
EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (events, mapper) {
    return events
        .transform(_DebounceStreamTransformer<E>(duration))
        .asyncExpand(mapper);
  };
}

class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  const _DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? timer;
    late StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        final sub = stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(data));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
        controller.onCancel = () {
          timer?.cancel();
          return sub.cancel();
        };
      },
    );

    return controller.stream;
  }
}

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
    on<FieldTypeOpened>(_onOpened);
    on<FieldTypeSearchChanged>(
      _onSearchChanged,
      transformer: _debounceRestartable(_kSearchDebounce),
    );
    on<FieldTypeNextPageRequested>(_onNextPage);
    on<CreateFieldRequested>(_onCreate);
  }

  // ── page fetching ───────────────────────────────────────────────────────

  /// Calls the right paginated use-case for [type] and maps the entities into
  /// [WidgetConfig]s via [WidgetConfigMapper] so the whole app shares one shape.
  Future<Either<Failure, Paginated<WidgetConfig>>> _fetch(
    FieldType type,
    int page,
    String search,
  ) async {
    Paginated<WidgetConfig> map<T>(
      Paginated<T> p,
      WidgetConfig Function(T) toWidget,
    ) =>
        Paginated(items: p.items.map(toWidget).toList(), meta: p.meta);

    switch (type) {
      case FieldType.textField:
        return (await getTextFields(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromTextField));
      case FieldType.textDropdown:
        return (await getTextDropdowns(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromTextDropdown));
      case FieldType.radioGroup:
        return (await getRadioGroups(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromRadioGroup));
      case FieldType.checkList:
        return (await getCheckLists(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromCheckList));
      case FieldType.datePicker:
        return (await getDatePickers(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromDatePicker));
      case FieldType.filePicker:
        return (await getFilePickers(page: page, limit: kFieldsPageSize, search: search))
            .map((p) => map(p, WidgetConfigMapper.fromFilePicker));
    }
  }

  // ── handlers ──────────────────────────────────────────────────────────────

  Future<void> _onOpened(
    FieldTypeOpened event,
    Emitter<FieldsState> emit,
  ) async {
    final current = state.of(event.type);
    // Skip if already loaded successfully and not forced.
    if (!event.forceReload &&
        current.status == RequestStatus.success &&
        current.items.isNotEmpty) {
      return;
    }
    await _loadFirstPage(event.type, current.search, emit);
  }

  Future<void> _onSearchChanged(
    FieldTypeSearchChanged event,
    Emitter<FieldsState> emit,
  ) async {
    await _loadFirstPage(event.type, event.query.trim(), emit);
  }

  /// Loads page 1 for [type] with [search], replacing the accumulated items.
  Future<void> _loadFirstPage(
    FieldType type,
    String search,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.withType(
      type,
      state.of(type).copyWith(
            status: RequestStatus.loading,
            search: search,
            error: null,
          ),
    ));

    final result = await _fetch(type, 1, search);

    result.fold(
      (failure) => emit(state.withType(
        type,
        state.of(type).copyWith(
              status: RequestStatus.failure,
              error: failure.message,
            ),
      )),
      (page) => emit(state.withType(
        type,
        state.of(type).copyWith(
              status: RequestStatus.success,
              items: page.items,
              meta: page.meta,
              error: null,
            ),
      )),
    );
  }

  Future<void> _onNextPage(
    FieldTypeNextPageRequested event,
    Emitter<FieldsState> emit,
  ) async {
    final current = state.of(event.type);
    if (current.loadingMore ||
        current.status == RequestStatus.loading ||
        !current.hasMore) {
      return;
    }

    emit(state.withType(event.type, current.copyWith(loadingMore: true)));

    final result = await _fetch(event.type, current.nextPage, current.search);

    result.fold(
      (failure) => emit(state.withType(
        event.type,
        state.of(event.type).copyWith(loadingMore: false, error: failure.message),
      )),
      (page) => emit(state.withType(
        event.type,
        state.of(event.type).copyWith(
              loadingMore: false,
              items: [...state.of(event.type).items, ...page.items],
              meta: page.meta,
              error: null,
            ),
      )),
    );
  }

  Future<void> _onCreate(
    CreateFieldRequested event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(createStatus: FormStatus.submitting, createError: null));

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
        emit(state.copyWith(createStatus: FormStatus.success));
        // Reload this type's first page (respecting the current search) so the
        // new field appears at the top of its dropdown.
        await _loadFirstPage(event.type, state.of(event.type).search, emit);
      },
    );
  }
}
