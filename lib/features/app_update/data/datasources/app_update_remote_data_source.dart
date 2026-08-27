import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
  AppUpdateRemoteDataSource({
    Dio? dio,
    this.currentVersion = '<unknown>',
    this.currentBuildNumber = '<unknown>',
  }) : _dio = dio ??
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
  final String currentVersion;
  final String currentBuildNumber;
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

    try {
      _printDiagnosticLog(
        response: response,
        currentVersionCode: currentVersionCode,
      );
    } catch (error) {
      // يجب ألا يؤثر أي فشل داخل التشخيص المؤقت في نتيجة فحص التحديث.
      debugPrint('[AppUpdate] diagnostic logging failed: $error');
    }

    final body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('استجابة فحص التحديث غير متوقَّعة');
  }

  /// سجل تشخيصي فقط: لا يشارك في اختيار الإصدار ولا يغيّر نتيجة الفحص.
  /// نقطة النهاية لا تعيد `is_active`؛ هي تعيد المرشح المؤهل فقط، لذلك نطبع
  /// غياب الحقل صراحةً بدلاً من افتراض true أو false.
  void _printDiagnosticLog({
    required Response<dynamic> response,
    required int currentVersionCode,
  }) {
    final rawBody = response.data;
    final requestParams = response.requestOptions.queryParameters;
    final platform = requestParams['platform'];
    final responseMap = rawBody is Map ? rawBody : null;
    final dataValue = responseMap?['data'];
    final data = dataValue is Map ? dataValue : responseMap;
    final appInfoValue = data?['app_info'];
    final appInfo = appInfoValue is Map ? appInfoValue : null;

    final latestVersion = appInfo?['version_name'];
    final latestBuildNumber = _asInt(appInfo?['version_code']);
    final forceUpdate = appInfo?['force_update'];
    final forceUpdateEnabled = _asBool(data?['force_update_enabled']);
    final shouldUpdate = appInfo != null;
    final shouldForceUpdate = shouldUpdate && forceUpdateEnabled;
    final comparisonResult = latestBuildNumber == null
        ? 'not evaluated (app_info=null; comparison is server-side)'
        : '$latestBuildNumber > $currentVersionCode = '
            '${latestBuildNumber > currentVersionCode} '
            '(diagnostic only; server selected app_info)';

    debugPrint('================ APP UPDATE CHECK ================');
    debugPrint('currentVersion = $currentVersion');
    debugPrint('currentBuildNumber = $currentBuildNumber '
        '(reported version code = $currentVersionCode)');
    debugPrint('application = $kAppUpdateApplicationName');
    debugPrint('platform = $platform');
    debugPrint('requestUrl = ${response.realUri}');
    debugPrint('requestParams = ${jsonEncode(requestParams)}');
    debugPrint('');
    debugPrint('responseStatus = ${response.statusCode}');
    debugPrint('rawResponse = ${_encode(rawBody)}');
    debugPrint('');
    debugPrint('latestVersion = ${latestVersion ?? '<not returned>'}');
    debugPrint(
      'latestBuildNumber = ${latestBuildNumber ?? '<not returned>'}',
    );
    debugPrint(
      'isActive = ${appInfo?.containsKey('is_active') == true ? appInfo!['is_active'] : '<not returned; endpoint exposes eligible candidate only>'}',
    );
    debugPrint('forceUpdate = ${forceUpdate ?? '<not returned>'}');
    debugPrint('downloadUrl = ${appInfo?['download_url'] ?? '<not returned>'}');
    debugPrint('');
    debugPrint('comparisonResult = $comparisonResult');
    debugPrint('shouldUpdate = $shouldUpdate');
    debugPrint('shouldForceUpdate = $shouldForceUpdate');
    debugPrint('==================================================');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static String _encode(dynamic value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}
