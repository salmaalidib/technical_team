import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../services/token_refresh_service.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create(
    SecureStorageService storage,
    TokenRefreshService refreshService,
  ) {
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
      AuthInterceptor(
        dio: dio,
        storage: storage,
        refreshService: refreshService,
      ),
    );

    // Only log full request/response bodies in debug builds — otherwise the
    // login password and access/refresh tokens would leak into release logs.
    //
    // PrettyDioLogger pretty-prints the JSON body across multiple lines (instead
    // of the single-line dump LogInterceptor produces) so the data is readable.
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: false,
          maxWidth: 120,
        ),
      );
    }

    return dio;
  }
}
