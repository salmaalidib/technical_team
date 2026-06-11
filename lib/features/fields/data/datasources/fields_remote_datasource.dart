import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

class FieldsRemoteDataSource {
  final ApiService api;

  FieldsRemoteDataSource(this.api);

  static const _ep = EndPoints();

  // ── text fields ───────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getTextFields() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.textFields);

  Future<Either<Failure, dynamic>> createTextField(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.textFields, body: body);

  // ── radio groups ──────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getRadioGroups() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.radioGroups);

  Future<Either<Failure, dynamic>> createRadioGroup(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.radioGroups, body: body);

  // ── text dropdowns ────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getTextDropdowns() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.textDropdowns);

  Future<Either<Failure, dynamic>> createTextDropdown(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.textDropdowns, body: body);

  // ── check lists ───────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getCheckLists() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.checkLists);

  Future<Either<Failure, dynamic>> createCheckList(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.checkLists, body: body);

  // ── date pickers ──────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getDatePickers() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.datePickers);

  Future<Either<Failure, dynamic>> createDatePicker(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.datePickers, body: body);

  // ── file pickers ──────────────────────────────────────────────────────────
  Future<Either<Failure, dynamic>> getFilePickers() =>
      api.makeRequest(method: ApiMethod.get, endPoint: _ep.filePickers);

  Future<Either<Failure, dynamic>> createFilePicker(
    Map<String, dynamic> body,
  ) =>
      api.makeRequest(
          method: ApiMethod.post, endPoint: _ep.filePickers, body: body);
}
