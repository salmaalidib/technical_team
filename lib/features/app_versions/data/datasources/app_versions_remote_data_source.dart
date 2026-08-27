import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// مسارات الأدمن لإدارة إصدارات التطبيقات الثلاثة.
///
/// على خلاف [AppUpdateRemoteDataSource] (الذي يبني `Dio` عارياً لأن
/// `GET /settings` نقطة نهاية عامة)، هذه المسارات كلها محمية بـ `authMiddleware`
/// + `authorize('APP_VERSION_MANAGE')`، فتمرّ عبر [ApiService] المشترك ليُرفق
/// التوكن ويُدار تجديده و401 كبقية الفيتشرات.
class AppVersionsRemoteDataSource {
  final ApiService api;

  AppVersionsRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getApplications() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.appUpdateApplications,
    );
  }

  Future<Either<Failure, dynamic>> updateApplication({
    required int appId,
    required Map<String, dynamic> body,
  }) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.appUpdateApplication(appId),
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> getVersions(int appId) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.appUpdateVersions(appId),
    );
  }

  Future<Either<Failure, dynamic>> createVersion({
    required int appId,
    required Map<String, dynamic> body,
  }) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.appUpdateVersions(appId),
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> updateVersion({
    required int appId,
    required int versionId,
    required Map<String, dynamic> body,
  }) {
    return api.makeRequest(
      method: ApiMethod.put,
      endPoint: _endPoints.appUpdateVersion(appId, versionId),
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> deleteVersion({
    required int appId,
    required int versionId,
  }) {
    return api.makeRequest(
      method: ApiMethod.delete,
      endPoint: _endPoints.appUpdateVersion(appId, versionId),
    );
  }
}
