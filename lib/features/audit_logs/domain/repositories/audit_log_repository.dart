import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/audit_log_filter.dart';
import '../entities/audit_logs_page.dart';

abstract class AuditLogRepository {
  /// صفحة من سجلات التدقيق. [cursor] من `next_cursor` للصفحة السابقة،
  /// و[filter] يُعاد إرساله مع كل صفحة كي تبقى النتائج ضمن نفس الفلترة.
  ///
  /// يتطلب صلاحية `VIEW_AUDIT_LOGS`؛ بدونها يردّ الخادم 403.
  Future<Either<Failure, AuditLogsPage>> getAuditLogs({
    AuditLogFilter filter,
    String? cursor,
    int limit,
  });
}
