import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/dynamic_field.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_remote_data_source.dart';
import '../models/dynamic_field_model.dart';

class FieldRepositoryImpl implements FieldRepository {
  final FieldRemoteDataSource remote;

  FieldRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  Map<String, dynamic> _body({
    required String name,
    required String type,
    List<String>? listValues,
  }) {
    return {
      'field_name': name.trim(),
      'field_type': type,
      if (listValues != null) 'list_json': listValues,
    };
  }

  @override
  Future<Either<Failure, List<DynamicField>>> getFields() async {
    final result = await remote.getFields();
    return result.fold<Either<Failure, List<DynamicField>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => DynamicFieldModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الحقول.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> createField({
    required String name,
    required String type,
    List<String>? listValues,
  }) async {
    final result = await remote.createField(
      _body(name: name, type: type, listValues: listValues),
    );
    return result.fold<Either<Failure, Unit>>(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateField({
    required int id,
    required String name,
    required String type,
    List<String>? listValues,
  }) async {
    final result = await remote.updateField(
      id,
      _body(name: name, type: type, listValues: listValues),
    );
    return result.fold<Either<Failure, Unit>>(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }
}
