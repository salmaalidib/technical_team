import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_data_source.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource remote;

  AppUpdateRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, UpdateCheckResult>> checkForUpdate({
    required int currentVersionCode,
  }) async {
    try {
      final json = await remote.fetchSettings(
        currentVersionCode: currentVersionCode,
      );
      return Right(UpdateCheckResult.fromJson(json));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('تعذّر الاتصال بالخادم للتحقق من التحديثات.'));
      }
      return Left(ServerFailure(
        _serverMessage(e.response?.data) ?? 'تعذّر التحقق من وجود تحديث.',
      ));
    } catch (_) {
      return const Left(ServerFailure('تعذّر التحقق من وجود تحديث.'));
    }
  }

  String? _serverMessage(dynamic data) {
    if (data is Map) return (data['message'] ?? data['error'])?.toString();
    return null;
  }
}
