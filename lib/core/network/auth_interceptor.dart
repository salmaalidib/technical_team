import 'package:dio/dio.dart';

import '../active_org/active_organization_cubit.dart';
import '../di/injection.dart';
import '../router/app_router.dart';
import '../services/api_const.dart';
import '../services/token_refresh_service.dart';
import '../storage/secure_storage_service.dart';

/// Attaches the access token to every request and transparently refreshes
/// it when the backend answers 401.
///
/// Refresh flow (mirrors `POST /api/auth/refresh`):
///   1. On 401, ask [TokenRefreshService] to refresh.
///   2. On success, replay the failed request (the service has already
///      persisted the new token pair; [onRequest] re-attaches it).
///   3. On failure, wipe the stored tokens and bounce to `/login`.
///
/// The single in-flight coalescing now lives in [TokenRefreshService], shared
/// with [PushSocket], so a 401 here and a socket reconnect can't double-refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storage,
    required TokenRefreshService refreshService,
  })  : _dio = dio,
        _storage = storage,
        _refreshService = refreshService;

  final Dio _dio;
  final SecureStorageService _storage;
  final TokenRefreshService _refreshService;

  static const _endPoints = EndPoints();

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

    final refreshed = await _refreshService.refresh();
    if (!refreshed) {
      // Refresh failed → session is over. clear() also wipes the persisted
      // active-org id; reset the cubit's in-memory state too so a re-login as
      // a different user doesn't inherit the previous organization.
      await _storage.clear();
      if (getIt.isRegistered<ActiveOrganizationCubit>()) {
        await getIt<ActiveOrganizationCubit>().clear();
      }
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
}
