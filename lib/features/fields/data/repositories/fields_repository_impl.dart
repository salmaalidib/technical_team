import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_result.dart';
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

  /// Maps a paginated list response (`data: { items: [...], pagination: {...} }`)
  /// into a [Paginated] of entities. Falls back to treating `data` itself as a
  /// bare list (legacy shape) so it stays compatible if the envelope changes.
  static Either<Failure, Paginated<T>> _parsePaginated<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
    String errorMessage,
  ) {
    try {
      final data = _payload(body);
      final rawItems = data is Map<String, dynamic>
          ? (data['items'] as List)
          : (data as List);
      final items = rawItems
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = data is Map<String, dynamic> && data['pagination'] is Map
          ? PageMeta.fromJson(
              (data['pagination'] as Map).cast<String, dynamic>())
          : PageMeta.empty;

      return Right(Paginated<T>(items: items, meta: meta));
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
  Future<Either<Failure, Paginated<TextFieldEntity>>> getTextFields({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getTextFields(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<TextFieldEntity>(
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
  Future<Either<Failure, Paginated<RadioGroupEntity>>> getRadioGroups({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getRadioGroups(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<RadioGroupEntity>(
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
  Future<Either<Failure, Paginated<TextDropdownEntity>>> getTextDropdowns({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getTextDropdowns(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<TextDropdownEntity>(
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
  Future<Either<Failure, Paginated<CheckListEntity>>> getCheckLists({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getCheckLists(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<CheckListEntity>(
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
  Future<Either<Failure, Paginated<DatePickerEntity>>> getDatePickers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getDatePickers(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<DatePickerEntity>(
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
  Future<Either<Failure, Paginated<FilePickerEntity>>> getFilePickers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final result =
        await remote.getFilePickers(page: page, limit: limit, search: search);
    return result.fold(
      Left.new,
      (data) => _parsePaginated<FilePickerEntity>(
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
