import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/type_doc.dart';
import '../../domain/repositories/type_doc_repository.dart';
import '../datasources/type_doc_remote_data_source.dart';
import '../models/type_doc_model.dart';

class TypeDocRepositoryImpl implements TypeDocRepository {
  final TypeDocRemoteDataSource remote;

  TypeDocRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  /// Extracts the list of items from a (possibly) paginated list response.
  /// The backend now returns `data: { items: [...], pagination: {...} }`, but
  /// this also accepts a bare `data: [...]` for backward compatibility.
  static List _listPayload(dynamic body) {
    final data = _payload(body);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return data['items'] as List;
    }
    return data as List;
  }

  @override
  Future<Either<Failure, List<TypeDoc>>> getTypeDocs() async {
    final result = await remote.getTypeDocs();
    return result.fold<Either<Failure, List<TypeDoc>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = _listPayload(body)
              .map((e) => TypeDocModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة أنواع المستندات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, TypeDoc>> createTypeDoc({required String name}) async {
    final result = await remote.createTypeDoc({'name': name.trim()});
    return result.fold<Either<Failure, TypeDoc>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            TypeDocModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, TypeDoc>> updateTypeDoc({
    required int id,
    String? name,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (isActive != null) 'is_active': isActive,
    };
    final result = await remote.updateTypeDoc(id, body);
    return result.fold<Either<Failure, TypeDoc>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            TypeDocModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر تحديث نوع المستند.'));
        }
      },
    );
  }
}
