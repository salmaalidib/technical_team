import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';
import '../data/datasources/fields_remote_datasource.dart';
import '../data/repositories/fields_repository_impl.dart';
import '../domain/repositories/fields_repository.dart';
import '../domain/usecases/create_check_list_usecase.dart';
import '../domain/usecases/create_date_picker_usecase.dart';
import '../domain/usecases/create_file_picker_usecase.dart';
import '../domain/usecases/create_radio_group_usecase.dart';
import '../domain/usecases/create_text_dropdown_usecase.dart';
import '../domain/usecases/create_text_field_usecase.dart';
import '../domain/usecases/get_check_lists_usecase.dart';
import '../domain/usecases/get_date_pickers_usecase.dart';
import '../domain/usecases/get_file_pickers_usecase.dart';
import '../domain/usecases/get_radio_groups_usecase.dart';
import '../domain/usecases/get_text_dropdowns_usecase.dart';
import '../domain/usecases/get_text_fields_usecase.dart';
import '../presentation/bloc/fields_bloc.dart';

/// Registers [T] as a lazy singleton only if it isn't already registered, so
/// calling [setupFieldsInjection] more than once is a no-op.
void _registerOnce<T extends Object>(T Function() factory) {
  if (!getIt.isRegistered<T>()) {
    getIt.registerLazySingleton<T>(factory);
  }
}

Future<void> setupFieldsInjection() async {
  _registerOnce<FieldsRemoteDataSource>(
    () => FieldsRemoteDataSource(getIt<ApiService>()),
  );
  _registerOnce<FieldsRepository>(
    () => FieldsRepositoryImpl(getIt<FieldsRemoteDataSource>()),
  );

  FieldsRepository repo() => getIt<FieldsRepository>();

  // ── get usecases ──────────────────────────────────────────────────────────
  _registerOnce<GetTextFieldsUseCase>(() => GetTextFieldsUseCase(repo()));
  _registerOnce<GetRadioGroupsUseCase>(() => GetRadioGroupsUseCase(repo()));
  _registerOnce<GetTextDropdownsUseCase>(() => GetTextDropdownsUseCase(repo()));
  _registerOnce<GetCheckListsUseCase>(() => GetCheckListsUseCase(repo()));
  _registerOnce<GetDatePickersUseCase>(() => GetDatePickersUseCase(repo()));
  _registerOnce<GetFilePickersUseCase>(() => GetFilePickersUseCase(repo()));

  // ── create usecases ───────────────────────────────────────────────────────
  _registerOnce<CreateTextFieldUseCase>(() => CreateTextFieldUseCase(repo()));
  _registerOnce<CreateRadioGroupUseCase>(() => CreateRadioGroupUseCase(repo()));
  _registerOnce<CreateTextDropdownUseCase>(
      () => CreateTextDropdownUseCase(repo()));
  _registerOnce<CreateCheckListUseCase>(() => CreateCheckListUseCase(repo()));
  _registerOnce<CreateDatePickerUseCase>(() => CreateDatePickerUseCase(repo()));
  _registerOnce<CreateFilePickerUseCase>(() => CreateFilePickerUseCase(repo()));

  // ── bloc ─────────────────────────────────────────────────────────────────
  if (!getIt.isRegistered<FieldsBloc>()) {
    getIt.registerFactory<FieldsBloc>(
      () => FieldsBloc(
        getTextFields: getIt<GetTextFieldsUseCase>(),
        getRadioGroups: getIt<GetRadioGroupsUseCase>(),
        getTextDropdowns: getIt<GetTextDropdownsUseCase>(),
        getCheckLists: getIt<GetCheckListsUseCase>(),
        getDatePickers: getIt<GetDatePickersUseCase>(),
        getFilePickers: getIt<GetFilePickersUseCase>(),
        createTextField: getIt<CreateTextFieldUseCase>(),
        createRadioGroup: getIt<CreateRadioGroupUseCase>(),
        createTextDropdown: getIt<CreateTextDropdownUseCase>(),
        createCheckList: getIt<CreateCheckListUseCase>(),
        createDatePicker: getIt<CreateDatePickerUseCase>(),
        createFilePicker: getIt<CreateFilePickerUseCase>(),
      ),
    );
  }
}
