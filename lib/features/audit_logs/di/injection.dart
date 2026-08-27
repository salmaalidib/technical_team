import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/audit_log_remote_data_source.dart';
import '../data/repositories/audit_log_repository_impl.dart';
import '../domain/repositories/audit_log_repository.dart';
import '../domain/usecases/get_audit_logs_usecase.dart';
import '../presentation/bloc/audit_logs_bloc.dart';

Future<void> setupAuditLogsInjection() async {
  if (!getIt.isRegistered<AuditLogRemoteDataSource>()) {
    getIt.registerLazySingleton<AuditLogRemoteDataSource>(
      () => AuditLogRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<AuditLogRepository>()) {
    getIt.registerLazySingleton<AuditLogRepository>(
      () => AuditLogRepositoryImpl(getIt<AuditLogRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetAuditLogsUseCase>()) {
    getIt.registerLazySingleton<GetAuditLogsUseCase>(
      () => GetAuditLogsUseCase(getIt<AuditLogRepository>()),
    );
  }

  // factory لا singleton: الشاشة تُنشئ الـ bloc عند فتحها وتتخلّص منه عند
  // الخروج، فلا تُستأنف الفلاتر والصفحات القديمة في زيارة لاحقة.
  if (!getIt.isRegistered<AuditLogsBloc>()) {
    getIt.registerFactory<AuditLogsBloc>(
      () => AuditLogsBloc(getAuditLogs: getIt<GetAuditLogsUseCase>()),
    );
  }
}
