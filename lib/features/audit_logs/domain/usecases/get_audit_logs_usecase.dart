import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/audit_log_filter.dart';
import '../entities/audit_logs_page.dart';
import '../repositories/audit_log_repository.dart';

class GetAuditLogsUseCase {
  final AuditLogRepository repository;

  GetAuditLogsUseCase(this.repository);

  Future<Either<Failure, AuditLogsPage>> call({
    AuditLogFilter filter = const AuditLogFilter(),
    String? cursor,
    int limit = 20,
  }) {
    return repository.getAuditLogs(
      filter: filter,
      cursor: cursor,
      limit: limit,
    );
  }
}
