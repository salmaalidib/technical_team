import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/doc_template.dart';
import '../../domain/entities/form_config.dart';
import '../../domain/repositories/doc_template_repository.dart';
import '../datasources/doc_template_remote_data_source.dart';
import '../models/doc_template_model.dart';

class DocTemplateRepositoryImpl implements DocTemplateRepository {
  final DocTemplateRemoteDataSource remote;

  DocTemplateRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, List<DocTemplate>>> getTemplates() async {
    final result = await remote.getTemplates();
    return result.fold<Either<Failure, List<DocTemplate>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => DocTemplateModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة القوالب.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, DocTemplate>> getTemplate(int id) async {
    final result = await remote.getTemplate(id);
    return result.fold<Either<Failure, DocTemplate>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            DocTemplateModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة بيانات القالب.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, DocTemplate>> createTemplate({
    required String name,
    required int typeDocId,
    required FormConfig config,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final result = await remote.createTemplate(
      fields: {
        'name': name.trim(),
        'type_doc_id': typeDocId,
        'config_json': jsonEncode(config.toJson()),
      },
      fileBytes: fileBytes,
      fileName: fileName,
    );

    return _readTemplate(result, 'تعذّر قراءة استجابة إنشاء القالب.');
  }

  @override
  Future<Either<Failure, DocTemplate>> updateTemplate({
    required int id,
    String? name,
    int? typeDocId,
    FormConfig? config,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final result = await remote.updateTemplate(
      id: id,
      fields: {
        if (name != null) 'name': name.trim(),
        if (typeDocId != null) 'type_doc_id': typeDocId,
        if (config != null) 'config_json': jsonEncode(config.toJson()),
      },
      fileBytes: fileBytes,
      fileName: fileName,
    );

    return _readTemplate(result, 'تعذّر قراءة استجابة تعديل القالب.');
  }

  Either<Failure, DocTemplate> _readTemplate(
    Either<Failure, dynamic> result,
    String parseError,
  ) {
    return result.fold<Either<Failure, DocTemplate>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            DocTemplateModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return Left(ServerFailure(parseError));
        }
      },
    );
  }
}
