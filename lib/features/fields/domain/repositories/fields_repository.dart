import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/check_list_entity.dart';
import '../entities/date_picker_entity.dart';
import '../entities/file_picker_entity.dart';
import '../entities/radio_group_entity.dart';
import '../entities/text_dropdown_entity.dart';
import '../entities/text_field_entity.dart';

abstract class FieldsRepository {
  // ── getters ──────────────────────────────────────────────────────────────
  Future<Either<Failure, List<TextFieldEntity>>> getTextFields();
  Future<Either<Failure, List<RadioGroupEntity>>> getRadioGroups();
  Future<Either<Failure, List<TextDropdownEntity>>> getTextDropdowns();
  Future<Either<Failure, List<CheckListEntity>>> getCheckLists();
  Future<Either<Failure, List<DatePickerEntity>>> getDatePickers();
  Future<Either<Failure, List<FilePickerEntity>>> getFilePickers();

  // ── creators ─────────────────────────────────────────────────────────────
  Future<Either<Failure, TextFieldEntity>> createTextField(
    Map<String, dynamic> body,
  );
  Future<Either<Failure, RadioGroupEntity>> createRadioGroup(
    Map<String, dynamic> body,
  );
  Future<Either<Failure, TextDropdownEntity>> createTextDropdown(
    Map<String, dynamic> body,
  );
  Future<Either<Failure, CheckListEntity>> createCheckList(
    Map<String, dynamic> body,
  );
  Future<Either<Failure, DatePickerEntity>> createDatePicker(
    Map<String, dynamic> body,
  );
  Future<Either<Failure, FilePickerEntity>> createFilePicker(
    Map<String, dynamic> body,
  );
}
