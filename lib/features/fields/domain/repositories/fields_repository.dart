import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/check_list_entity.dart';
import '../entities/date_picker_entity.dart';
import '../entities/file_picker_entity.dart';
import '../entities/radio_group_entity.dart';
import '../entities/text_dropdown_entity.dart';
import '../entities/text_field_entity.dart';

abstract class FieldsRepository {
  // ── getters (paginated + searchable) ───────────────────────────────────────
  Future<Either<Failure, Paginated<TextFieldEntity>>> getTextFields({
    int page,
    int limit,
    String? search,
  });
  Future<Either<Failure, Paginated<RadioGroupEntity>>> getRadioGroups({
    int page,
    int limit,
    String? search,
  });
  Future<Either<Failure, Paginated<TextDropdownEntity>>> getTextDropdowns({
    int page,
    int limit,
    String? search,
  });
  Future<Either<Failure, Paginated<CheckListEntity>>> getCheckLists({
    int page,
    int limit,
    String? search,
  });
  Future<Either<Failure, Paginated<DatePickerEntity>>> getDatePickers({
    int page,
    int limit,
    String? search,
  });
  Future<Either<Failure, Paginated<FilePickerEntity>>> getFilePickers({
    int page,
    int limit,
    String? search,
  });

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
