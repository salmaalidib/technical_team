import 'dart:async';

import 'package:dio/dio.dart';

import '../router/app_router.dart';
import '../services/api_const.dart';
import '../storage/secure_storage_service.dart';

/// Attaches the access token to every request and transparently refreshes
/// it when the backend answers 401.
///
/// Refresh flow (mirrors `POST /api/auth/refresh`):
///   1. On 401, call `/api/auth/refresh` with the stored refresh token.
///   2. On success, persist the new token pair and replay the failed request
///      (and any other requests that hit 401 while the refresh was in flight).
///   3. On failure, wipe the stored tokens and bounce to `/login`.
///
/// A single in-flight refresh is shared via [_refreshCompleter] so concurrent
/// 401s trigger exactly one refresh call (the queue), then all retry.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storage,
  })  : _dio = dio,
        _storage = storage,
        // Bare Dio with no interceptors → used only for the refresh call so it
        // can never recurse back into this interceptor.
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;
  final Dio _refreshDio;
  final SecureStorageService _storage;

  static const _endPoints = EndPoints();

  /// Non-null while a refresh is in flight; completes with `true` on success.
  Completer<bool>? _refreshCompleter;

  bool _isAuthFlowPath(String path) =>
      path.contains(_endPoints.login) ||
      path.contains(_endPoints.verifyLoginOtp) ||
      path.contains(_endPoints.refresh) ||
      path.contains(_endPoints.logout);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't attach the (possibly stale) access token to the auth flow itself.
    if (!_isAuthFlowPath(options.path)) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;

    // Only try to refresh genuine 401s on protected endpoints, and never for
    // the auth flow (a 401 there is a real credential error).
    if (!isUnauthorized ||
        _isAuthFlowPath(err.requestOptions.path) ||
        err.requestOptions.extra['__retried__'] == true) {
      return handler.next(err);
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      // Refresh failed → session is over.
      await _storage.clear();
      AppRouter.router.go('/login');
      return handler.next(err);
    }

    // Replay the original request once with the fresh token. We only flag it
    // as retried here — onRequest re-attaches the freshly stored access token,
    // so there's no need to set the Authorization header manually.
    try {
      final options = err.requestOptions;
      options.extra['__retried__'] = true;
      final retryResponse = await _dio.fetch(options);
      return handler.resolve(retryResponse);
    } catch (e) {
      if (e is DioException) return handler.next(e);
      return handler.next(err);
    }
  }

  /// Refreshes the token pair, coalescing concurrent callers onto one request.
  Future<bool> _refreshTokens() {
    // A refresh is already running — wait for its result (the queue).
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
        // Tolerate both the nested `{ data: { token, refreshToken } }` shape
        // used by the rest of the auth responses and a flat
        // `{ token, refreshToken }` payload, so a backend tweak to the refresh
        // envelope can't silently break the refresh flow.
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
