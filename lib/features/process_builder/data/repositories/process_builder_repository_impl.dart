import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_process_item.dart';
import '../../domain/entities/created_process.dart';
import '../../domain/entities/missing_config_item.dart';
import '../../domain/entities/process_details.dart';
import '../../domain/entities/review_queue_item.dart';
import '../../domain/repositories/process_builder_repository.dart';
import '../datasources/process_builder_remote_data_source.dart';
import '../models/admin_process_item_model.dart';
import '../models/created_process_model.dart';
import '../models/missing_config_item_model.dart';
import '../models/process_details_model.dart';
import '../models/review_queue_item_model.dart';

class ProcessBuilderRepositoryImpl implements ProcessBuilderRepository {
  final ProcessBuilderRemoteDataSource remote;

  ProcessBuilderRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, CreatedProcess>> createProcessDefinition({
    required String name,
    required bool isComplaint,
    int? typeTransId,
    required int organizationId,
    required int priority,
    required String startDate,
    String? endDate,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final fields = <String, dynamic>{
      'name': name.trim(),
      'is_complaint': isComplaint,
      'organization_id': organizationId,
      'priority': priority,
      'start_date': startDate,
    };

    // type_trans_id only for normal transactions (شكوى → null on the backend).
    if (!isComplaint && typeTransId != null) {
      fields['type_trans_id'] = typeTransId;
    }
    if (endDate != null && endDate.isNotEmpty) {
      fields['end_date'] = endDate;
    }

    final result = await remote.createProcessDefinition(
      fields: fields,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    return result.fold<Either<Failure, CreatedProcess>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            CreatedProcessModel.fromCreateResponse(
              _payload(body) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة إنشاء العملية.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> configureStages(
    List<Map<String, dynamic>> stages,
  ) async {
    final result = await remote.createStageConfig({'stages': stages});

    return result.fold<Either<Failure, void>>(
      (failure) => Left(failure),
      (_) => const Right(null),
    );
  }

  /// Pulls the `items` array out of the `{ items, pagination }` payload.
  static List _items(dynamic payload) =>
      (payload is Map<String, dynamic> ? payload['items'] : payload) as List? ??
      const [];

  @override
  Future<Either<Failure, List<ReviewQueueItem>>> getReviewQueue({
    int page = 1,
    int limit = 100,
  }) async {
    final result = await remote.getReviewQueue(page: page, limit: limit);

    return result.fold<Either<Failure, List<ReviewQueueItem>>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            _items(_payload(body))
                .map<ReviewQueueItem>(
                  (e) => ReviewQueueItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة المراجعة.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<MissingConfigItem>>> getMissingStageConfig({
    int page = 1,
    int limit = 100,
  }) async {
    final result = await remote.getMissingStageConfig(page: page, limit: limit);

    return result.fold<Either<Failure, List<MissingConfigItem>>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            _items(_payload(body))
                .map<MissingConfigItem>(
                  (e) => MissingConfigItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          );
        } catch (_) {
          return const Left(
              ServerFailure('تعذّر قراءة قائمة العمليات غير المكتملة.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> reviewProcess({
    required int id,
    required String decision,
  }) async {
    final result = await remote.reviewProcess(id: id, decision: decision);

    return result.fold<Either<Failure, void>>(
      (failure) => Left(failure),
      (_) => const Right(null),
    );
  }

  @override
  Future<Either<Failure, List<AdminProcessItem>>> getProcessesByType({
    int typeId = 0,
    int page = 1,
    int limit = 100,
  }) async {
    final result = await remote.getProcessesByType(
      typeId: typeId,
      page: page,
      limit: limit,
    );

    return result.fold<Either<Failure, List<AdminProcessItem>>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            _items(_payload(body))
                .map<AdminProcessItem>(
                  (e) => AdminProcessItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة العمليات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, ProcessDetails>> getProcessDetails(int id) async {
    final result = await remote.getProcessDetails(id);

    return result.fold<Either<Failure, ProcessDetails>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            ProcessDetailsModel.fromJson(
              _payload(body) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة تفاصيل العملية.'));
        }
      },
    );
  }
}
