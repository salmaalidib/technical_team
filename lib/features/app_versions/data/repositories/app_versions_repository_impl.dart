import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_version_row.dart';
import '../../domain/entities/managed_application.dart';
import '../../domain/repositories/app_versions_repository.dart';
import '../datasources/app_versions_remote_data_source.dart';

class AppVersionsRepositoryImpl implements AppVersionsRepository {
  final AppVersionsRemoteDataSource remote;

  AppVersionsRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  /// The list endpoints return the rows directly under `data`; a `Map` slips
  /// through only when the backend wraps them again, so both shapes are read.
  static List<dynamic> _asList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in const ['rows', 'items', 'data']) {
        final nested = payload[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic payload) =>
      Map<String, dynamic>.from(payload as Map);

  /// الواجهة تدير إصدارات تطبيق التقني فقط. الخادم يرجع التطبيقات الثلاثة
  /// (المواطن / الموظف / التقني)، فنُرشِّحها هنا — نقطة واحدة تمرّ منها كل
  /// الشاشات، فلا يتسرّب تطبيق آخر إلى التبويبات أو إلى الاختيار التلقائي.
  static const _visibleApplication = 'technical_team';

  @override
  Future<Either<Failure, List<ManagedApplication>>> getApplications() async {
    final result = await remote.getApplications();
    return result.fold<Either<Failure, List<ManagedApplication>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = _asList(_payload(body))
              .map((e) => ManagedApplication.fromJson(_asMap(e)))
              .where((app) => app.name == _visibleApplication)
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة التطبيقات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, ManagedApplication>> updateApplication({
    required int appId,
    required Map<String, dynamic> body,
  }) async {
    final result = await remote.updateApplication(appId: appId, body: body);
    return result.fold<Either<Failure, ManagedApplication>>(
      (failure) => Left(failure),
      (data) {
        try {
          return Right(ManagedApplication.fromJson(_asMap(_payload(data))));
        } catch (_) {
          return const Left(
              ServerFailure('تعذّر قراءة بيانات التطبيق بعد التعديل.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<AppVersionRow>>> getVersions(int appId) async {
    final result = await remote.getVersions(appId);
    return result.fold<Either<Failure, List<AppVersionRow>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = _asList(_payload(body))
              .map((e) => AppVersionRow.fromJson(_asMap(e)))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الإصدارات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, AppVersionRow>> createVersion({
    required int appId,
    required Map<String, dynamic> body,
  }) async {
    final result = await remote.createVersion(appId: appId, body: body);
    return result.fold<Either<Failure, AppVersionRow>>(
      (failure) => Left(failure),
      (data) {
        try {
          return Right(AppVersionRow.fromJson(_asMap(_payload(data))));
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة الإصدار بعد إنشائه.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, AppVersionRow>> updateVersion({
    required int appId,
    required int versionId,
    required Map<String, dynamic> body,
  }) async {
    final result = await remote.updateVersion(
      appId: appId,
      versionId: versionId,
      body: body,
    );
    return result.fold<Either<Failure, AppVersionRow>>(
      (failure) => Left(failure),
      (data) {
        try {
          return Right(AppVersionRow.fromJson(_asMap(_payload(data))));
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة الإصدار بعد تعديله.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteVersion({
    required int appId,
    required int versionId,
  }) async {
    final result =
        await remote.deleteVersion(appId: appId, versionId: versionId);
    return result.fold<Either<Failure, Unit>>(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }
}
