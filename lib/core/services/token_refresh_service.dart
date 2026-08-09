import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_const.dart';
import '../storage/secure_storage_service.dart';

/// خدمة تجديد التوكن المشتركة.
///
/// تملك مكالمة تجديد واحدة منسّقة (coalesced) عبر `POST /api/auth/refresh`،
/// وتخزّن زوج التوكن الجديد. يستخدمها **كلٌّ** من [AuthInterceptor] (عند 401)
/// و[PushSocket] (عند إغلاق اتصال يُرجَّح أنه بسبب توكن منتهٍ) — فمنطق التجديد
/// مصدرٌ واحد، وأي طلبَي تجديد متزامنين يتشاركان مكالمة شبكة واحدة.
///
/// مسؤوليتها تنتهي عند إرجاع `bool`: **لا تنقّل ولا تلمس أي cubit**. كلّ مستدعٍ
/// يقرّر ماذا يفعل عند الفشل (الـ interceptor يمسح الجلسة ويوجّه إلى `/login`؛
/// الـ socket يتباطأ وينتظر جلسة جديدة).
///
/// الاستثناء الوحيد: عند 401 من نقطة التجديد نفسها (رفض الخادم للـ refresh
/// token) تمسح التوكنات فقط — لأنّ تكرار الطلب بتوكن رفضه الخادم لن ينجح أبداً،
/// فالمسح يوقف الحلقة العقيمة ويجعل كل مستدعٍ لاحق يرى "لا جلسة" فوراً.
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
      debugPrint('🔑 [TokenRefresh] لا يوجد refresh token مخزَّن — إلغاء.');
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '/${_endPoints.refresh}',
        data: {'refreshToken': refreshToken},
      );

      debugPrint(
        '🔑 [TokenRefresh] استجابة ${response.statusCode} من '
        '/${_endPoints.refresh}: ${response.data}',
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
          debugPrint('🔑 [TokenRefresh] نجح التجديد وتم حفظ التوكن الجديد.');
          return true;
        }
        debugPrint(
          '🔑 [TokenRefresh] استجابة 200 لكن الحقول token/refreshToken '
          'مفقودة أو فارغة في الجسم.',
        );
      }
      return false;
    } on DioException catch (e) {
      debugPrint(
        '🔑 [TokenRefresh] فشل الطلب: ${e.type} — '
        'status=${e.response?.statusCode} body=${e.response?.data} — '
        '${e.message}',
      );

      // 401 على نقطة التجديد = الخادم رفض الـ refresh token نفسه (منتهٍ، مُبطل،
      // أو أُنهيت الجلسات لكشف إعادة استخدام) — لا يُصلحه تكرار المحاولة بنفس
      // التوكن. نمسحه كي يتوقّف كل مستدعٍ عن قصف الخادم بتوكن ميت، وتُعامَل
      // المحاولات التالية كـ"لا جلسة" حتى يسجّل المستخدم الدخول من جديد.
      if (e.response?.statusCode == 401) {
        await _storage.deleteToken();
        await _storage.deleteRefreshToken();
        debugPrint(
          '🔑 [TokenRefresh] رفض الخادم الـ refresh token — '
          'مُسِحت التوكنات، مطلوب تسجيل دخول جديد.',
        );
      }

      return false;
    }
  }
}
