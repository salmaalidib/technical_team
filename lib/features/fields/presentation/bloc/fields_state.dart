import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/check_list_entity.dart';
import '../../domain/entities/date_picker_entity.dart';
import '../../domain/entities/field_type.dart';
import '../../domain/entities/file_picker_entity.dart';
import '../../domain/entities/radio_group_entity.dart';
import '../../domain/entities/text_dropdown_entity.dart';
import '../../domain/entities/text_field_entity.dart';

class FieldsState extends Equatable {
  final RequestStatus loadStatus;
  final String? error;

  final FieldType selectedType;

  final List<TextFieldEntity> textFields;
  final List<RadioGroupEntity> radioGroups;
  final List<TextDropdownEntity> textDropdowns;
  final List<CheckListEntity> checkLists;
  final List<DatePickerEntity> datePickers;
  final List<FilePickerEntity> filePickers;

  final FormStatus createStatus;
  final String? createError;

  const FieldsState({
    this.loadStatus = RequestStatus.initial,
    this.error,
    this.selectedType = FieldType.textField,
    this.textFields = const [],
    this.radioGroups = const [],
    this.textDropdowns = const [],
    this.checkLists = const [],
    this.datePickers = const [],
    this.filePickers = const [],
    this.createStatus = FormStatus.idle,
    this.createError,
  });

  int countOf(FieldType type) => switch (type) {
        FieldType.textField => textFields.length,
        FieldType.radioGroup => radioGroups.length,
        FieldType.textDropdown => textDropdowns.length,
        FieldType.checkList => checkLists.length,
        FieldType.datePicker => datePickers.length,
        FieldType.filePicker => filePickers.length,
      };

  FieldsState copyWith({
    RequestStatus? loadStatus,
    String? error,
    FieldType? selectedType,
    List<TextFieldEntity>? textFields,
    List<RadioGroupEntity>? radioGroups,
    List<TextDropdownEntity>? textDropdowns,
    List<CheckListEntity>? checkLists,
    List<DatePickerEntity>? datePickers,
    List<FilePickerEntity>? filePickers,
    FormStatus? createStatus,
    String? createError,
  }) {
    return FieldsState(
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
      selectedType: selectedType ?? this.selectedType,
      textFields: textFields ?? this.textFields,
      radioGroups: radioGroups ?? this.radioGroups,
      textDropdowns: textDropdowns ?? this.textDropdowns,
      checkLists: checkLists ?? this.checkLists,
      datePickers: datePickers ?? this.datePickers,
      filePickers: filePickers ?? this.filePickers,
      createStatus: createStatus ?? this.createStatus,
      createError: createError,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        error,
        selectedType,
        textFields,
        radioGroups,
        textDropdowns,
        checkLists,
        datePickers,
        filePickers,
        createStatus,
        createError,
      ];
}
