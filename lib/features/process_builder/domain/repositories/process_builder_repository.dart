import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_process_item.dart';
import '../entities/created_process.dart';
import '../entities/process_details.dart';
import '../entities/review_queue_item.dart';

/// Builds a process definition for the technical team:
/// 1. [createProcessDefinition] → `POST /api/process_definitions/create`
///    (multipart BPMN + metadata) which also generates the stages.
/// 2. [configureStages] → `POST /api/stage_config/create` (forms + assignments).
///
/// It also exposes the read side used by the listing/details screens:
/// [getReviewQueue], [getProcessesByType] and [getProcessDetails].
///
/// Approval/activation (`review`) is intentionally NOT here — it happens
/// elsewhere in the app.
abstract class ProcessBuilderRepository {
  Future<Either<Failure, CreatedProcess>> createProcessDefinition({
    required String name,
    required bool isComplaint,
    int? typeTransId,
    required int organizationId,
    required int priority,
    required String startDate, // MM-DD
    String? endDate, // MM-DD
    required List<int> fileBytes,
    required String fileName,
  });

  Future<Either<Failure, void>> configureStages(
    List<Map<String, dynamic>> stages,
  );

  /// `GET /api/process_definitions/admin/review-queue` — unapproved/inactive.
  Future<Either<Failure, List<ReviewQueueItem>>> getReviewQueue({
    int page = 1,
    int limit = 100,
  });

  /// `GET /api/process_definitions/admin/type/{id}` (`typeId` `0` = all types).
  Future<Either<Failure, List<AdminProcessItem>>> getProcessesByType({
    int typeId = 0,
    int page = 1,
    int limit = 100,
  });

  /// `GET /api/process_definitions/{id}/details`.
  Future<Either<Failure, ProcessDetails>> getProcessDetails(int id);
}
