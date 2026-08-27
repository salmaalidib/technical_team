import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/audit_log_filter.dart';
import '../../domain/entities/audit_logs_page.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_data_source.dart';
import '../models/audit_logs_page_model.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogRemoteDataSource remote;

  AuditLogRepositoryImpl(this.remote);

  /// يفكّ غلاف `{ success, status_code, message, data }` ويُرجع محتوى data.
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, AuditLogsPage>> getAuditLogs({
    AuditLogFilter filter = const AuditLogFilter(),
    String? cursor,
    int limit = 20,
  }) async {
    final result = await remote.getAuditLogs(
      filter: filter,
      cursor: cursor,
      limit: limit,
    );

    return result.fold(
      Left.new,
      (body) {
        final data = _payload(body);
        if (data is! Map) return const Right(AuditLogsPage());
        return Right(
          AuditLogsPageModel.fromJson(Map<String, dynamic>.from(data)),
        );
      },
    );
  }
}
