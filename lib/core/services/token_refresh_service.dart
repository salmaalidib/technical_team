import 'dart:async';

import 'package:dio/dio.dart';

import 'api_const.dart';
import '../storage/secure_storage_service.dart';

/// خدمة تجديد التوكن المشتركة.
///
/// تملك مكالمة تجديد واحدة منسّقة (coalesced) عبر `POST /api/auth/refresh`،
/// وتخزّن زوج التوكن الجديد. يستخدمها **كلٌّ** من [AuthInterceptor] (عند 401)
/// و[PushSocket] (عند إغلاق اتصال يُرجَّح أنه بسبب توكن منتهٍ) — فمنطق التجديد
/// مصدرٌ واحد، وأي طلبَي تجديد متزامنين يتشاركان مكالمة شبكة واحدة.
///
/// مسؤوليتها تنتهي عند إرجاع `bool`: **لا تنقّل، ولا تمسح التخزين، ولا تلمس
/// أي cubit**. كلّ مستدعٍ يقرّر ماذا يفعل عند الفشل (الـ interceptor يمسح ويوجّه
/// إلى `/login`؛ الـ socket يتوقّف فقط).
class TokenRefreshService {
  TokenRefreshService({
    required SecureStorageService storage,
    Dio? refreshDio,
  })  : _storage = storage,
        // Dio عارٍ بلا interceptors → يُستخدم لمكالمة التجديد فقط كي لا يعاود
        // الدخول إلى AuthInterceptor (تفادي العَودية). يقرأ baseUrl من نفس
        // مصدر DioClient.create (dotenv['BASE_URL']).
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: const ApiConstants().baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final SecureStorageService _storage;
  final Dio _refreshDio;

  static const _endPoints = EndPoints();

  /// غير فارغ أثناء وجود تجديد قيد التنفيذ؛ يكتمل بـ `true` عند النجاح.
  Completer<bool>? _refreshCompleter;

  /// يجدّد زوج التوكن، مع تنسيق المستدعين المتزامنين على مكالمة واحدة.
  ///
  /// لو كان هناك تجديد جارٍ، يعيد نتيجته نفسها (الطابور)؛ وإلّا يبدأ واحدًا.
  Future<bool> refresh() {
    // تجديد جارٍ بالفعل — انتظر نتيجته (الطابور).
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    _performRefresh().then((ok) {
      completer.complete(ok);
    }).catchError((_) {
      completer.complete(false);
    }).whenComplete(() {
      _refreshCompleter = null;
    });

    return completer.future;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '/${_endPoints.refresh}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        // نتسامح مع الشكلين: المتداخل `{ data: { token, refreshToken } }`
        // المستخدم في بقية استجابات المصادقة، والمسطّح `{ token, refreshToken }`،
        // كي لا يكسر أي تعديل في غلاف الاستجابة تدفّق التجديد بصمت.
        final tokens = (body is Map && body['data'] is Map)
            ? body['data'] as Map
            : (body is Map ? body : const {});
        final newToken = tokens['token'] as String?;
        final newRefreshToken = tokens['refreshToken'] as String?;

        if (newToken != null &&
            newToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          await _storage.saveTokens(
            token: newToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }
      return false;
    } on DioException {
      return false;
    }
  }
}
