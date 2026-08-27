import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/audit_log_filter.dart';

class AuditLogRemoteDataSource {
  final ApiService api;

  AuditLogRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getAuditLogs({
    AuditLogFilter filter = const AuditLogFilter(),
    String? cursor,
    int limit = 20,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.auditLogs,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (filter.userId != null) 'user_id': filter.userId,
        if (filter.action != null && filter.action!.isNotEmpty)
          'action': filter.action,
        if (filter.status?.code != null) 'status': filter.status!.code,
        if (filter.resourceType != null && filter.resourceType!.isNotEmpty)
          'resource_type': filter.resourceType,
        if (filter.fromDate != null) 'from_date': _day(filter.fromDate!),
        if (filter.toDate != null) 'to_date': _day(filter.toDate!),
      },
    );
  }

  /// الخادم يرفض أي صيغة غير `YYYY-MM-DD` بـ 400، فنبنيها يدوياً بدل
  /// `toIso8601String()` الذي يضيف جزء الوقت.
  static String _day(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
