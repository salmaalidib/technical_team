import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../../../../core/services/api_const.dart';

/// اسم التطبيق كما هو مسجَّل في جدول `applications` على الخادم.
const String kAppUpdateApplicationName = 'technical_team';

/// مصدر بيانات فحص التحديث. يبني `Dio` عارياً بلا interceptors خاصاً به —
/// بنفس أسلوب `TokenRefreshService._refreshDio` — لأن `GET /settings` نقطة
/// نهاية عامة بلا مصادقة؛ استخدام `getIt<Dio>()` المرفق بـ AuthInterceptor
/// كان سيحاول تجديد التوكن أو التوجيه إلى /login عند أي 401 غير متوقَّع، وهو
/// سلوك خاطئ هنا. أيضاً تُستخدم لتنزيل ملف المثبت نفسه (بلا رأس Authorization
/// — انظر توثيق الميزة، §2.4: الرابط يجب أن يعمل بلا جلسة).
class AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: const ApiConstants().baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;
  static const _endPoints = EndPoints();

  /// عارٍ بلا interceptors — يُستخدم أيضاً لتنزيل المثبت (لا Authorization).
  Dio get downloadClient => _dio;

  Future<Map<String, dynamic>> fetchSettings({
    required int currentVersionCode,
  }) async {
    final response = await _dio.get(
      _endPoints.appUpdateSettings,
      queryParameters: {
        'app': kAppUpdateApplicationName,
        'platform': Platform.isWindows ? 'windows' : 'android',
        'current_version_code': currentVersionCode,
      },
    );

    final body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('استجابة فحص التحديث غير متوقَّعة');
  }
}
