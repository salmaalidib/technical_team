import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/file_definition.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/file_remote_data_source.dart';
import '../models/file_definition_model.dart';

class FileRepositoryImpl implements FileRepository {
  final FileRemoteDataSource remote;

  FileRepositoryImpl(this.remote);

  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  Map<String, dynamic> _body({
    required String name,
    required String fileType,
    required String classification,
  }) {
    return {
      'file_name': name.trim(),
      'file_type': fileType,
      'type': classification,
    };
  }

  @override
  Future<Either<Failure, List<FileDefinition>>> getFiles() async {
    final result = await remote.getFiles();
    return result.fold<Either<Failure, List<FileDefinition>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) =>
                  FileDefinitionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الملفات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> createFile({
    required String name,
    required String fileType,
    required String classification,
  }) async {
    final result = await remote.createFile(
      _body(name: name, fileType: fileType, classification: classification),
    );
    return result.fold<Either<Failure, Unit>>(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateFile({
    required int id,
    required String name,
    required String fileType,
    required String classification,
  }) async {
    final result = await remote.updateFile(
      id,
      _body(name: name, fileType: fileType, classification: classification),
    );
    return result.fold<Either<Failure, Unit>>(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }
}
