import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create(SecureStorageService storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attaches the access token + transparently refreshes it on 401.
    dio.interceptors.add(
      AuthInterceptor(dio: dio, storage: storage),
    );

    // Only log full request/response bodies in debug builds — otherwise the
    // login password and access/refresh tokens would leak into release logs.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    return dio;
  }
}
