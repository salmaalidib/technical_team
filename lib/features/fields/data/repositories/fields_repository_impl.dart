import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/check_list_entity.dart';
import '../../domain/entities/date_picker_entity.dart';
import '../../domain/entities/file_picker_entity.dart';
import '../../domain/entities/radio_group_entity.dart';
import '../../domain/entities/text_dropdown_entity.dart';
import '../../domain/entities/text_field_entity.dart';
import '../../domain/repositories/fields_repository.dart';
import '../datasources/fields_remote_datasource.dart';
import '../models/check_list_model.dart';
import '../models/date_picker_model.dart';
import '../models/file_picker_model.dart';
import '../models/radio_group_model.dart';
import '../models/text_dropdown_model.dart';
import '../models/text_field_model.dart';

class FieldsRepositoryImpl implements FieldsRepository {
  final FieldsRemoteDataSource remote;

  FieldsRepositoryImpl(this.remote);

  /// Unwraps the `{data: ...}` envelope when present; otherwise returns [body].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  /// Maps the `data` array of a list response into entities, converting any
  /// shape mismatch into a [ServerFailure] carrying [errorMessage].
  static Either<Failure, List<T>> _parseList<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
    String errorMessage,
  ) {
    try {
      final list = (_payload(body) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (_) {
      return Left(ServerFailure(errorMessage));
    }
  }

  /// Maps the `data` object of a single-item response into an entity.
  static Either<Failure, T> _parseOne<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return Right(fromJson(_payload(body) as Map<String, dynamic>));
    } catch (_) {
      return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
    }
  }

  // ── text fields ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<TextFieldEntity>>> getTextFields() async {
    final result = await remote.getTextFields();
    return result.fold(
      Left.new,
      (data) => _parseList<TextFieldEntity>(
          data, TextFieldModel.fromJson, 'تعذّر قراءة قائمة حقول النص.'),
    );
  }

  @override
  Future<Either<Failure, TextFieldEntity>> createTextField(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createTextField(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<TextFieldEntity>(data, TextFieldModel.fromJson),
    );
  }

  // ── radio groups ──────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<RadioGroupEntity>>> getRadioGroups() async {
    final result = await remote.getRadioGroups();
    return result.fold(
      Left.new,
      (data) => _parseList<RadioGroupEntity>(
          data, RadioGroupModel.fromJson, 'تعذّر قراءة قائمة الاختيار الواحد.'),
    );
  }

  @override
  Future<Either<Failure, RadioGroupEntity>> createRadioGroup(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createRadioGroup(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<RadioGroupEntity>(data, RadioGroupModel.fromJson),
    );
  }

  // ── text dropdowns ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<TextDropdownEntity>>> getTextDropdowns() async {
    final result = await remote.getTextDropdowns();
    return result.fold(
      Left.new,
      (data) => _parseList<TextDropdownEntity>(
          data, TextDropdownModel.fromJson, 'تعذّر قراءة قائمة المنسدل.'),
    );
  }

  @override
  Future<Either<Failure, TextDropdownEntity>> createTextDropdown(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createTextDropdown(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<TextDropdownEntity>(data, TextDropdownModel.fromJson),
    );
  }

  // ── check lists ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<CheckListEntity>>> getCheckLists() async {
    final result = await remote.getCheckLists();
    return result.fold(
      Left.new,
      (data) => _parseList<CheckListEntity>(
          data, CheckListModel.fromJson, 'تعذّر قراءة قائمة الاختيار المتعدد.'),
    );
  }

  @override
  Future<Either<Failure, CheckListEntity>> createCheckList(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createCheckList(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<CheckListEntity>(data, CheckListModel.fromJson),
    );
  }

  // ── date pickers ──────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<DatePickerEntity>>> getDatePickers() async {
    final result = await remote.getDatePickers();
    return result.fold(
      Left.new,
      (data) => _parseList<DatePickerEntity>(
          data, DatePickerModel.fromJson, 'تعذّر قراءة قائمة منتقي التاريخ.'),
    );
  }

  @override
  Future<Either<Failure, DatePickerEntity>> createDatePicker(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createDatePicker(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<DatePickerEntity>(data, DatePickerModel.fromJson),
    );
  }

  // ── file pickers ──────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<FilePickerEntity>>> getFilePickers() async {
    final result = await remote.getFilePickers();
    return result.fold(
      Left.new,
      (data) => _parseList<FilePickerEntity>(
          data, FilePickerModel.fromJson, 'تعذّر قراءة قائمة منتقي الملفات.'),
    );
  }

  @override
  Future<Either<Failure, FilePickerEntity>> createFilePicker(
    Map<String, dynamic> body,
  ) async {
    final result = await remote.createFilePicker(body);
    return result.fold(
      Left.new,
      (data) => _parseOne<FilePickerEntity>(data, FilePickerModel.fromJson),
    );
  }
}
