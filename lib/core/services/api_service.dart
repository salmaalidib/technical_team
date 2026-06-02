import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;

import '../enums/api_method.dart';
import '../errors/failures.dart';

/// The single entry point for every network call in the app.
///
/// Returns `Either<Failure, dynamic>`:
///   * `Left(Failure)` — a mapped, ready-to-display error.
///   * `Right(data)`   — the decoded response body on any 2xx.
///
/// Status-code / timeout / connectivity mapping lives here and nowhere else, so
/// every feature behaves identically. Token attach/refresh and the
/// `401 → /login` redirect are owned by the `AuthInterceptor`; this service
/// never touches tokens or navigation.
class 
ApiService {
  final dio.Dio _dio;

  ApiService(this._dio);

  Future<Either<Failure, dynamic>> makeRequest({
    required ApiMethod method,
    required String endPoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    dio.FormData? formData,
    Map<String, dynamic>? headers,
  }) async {
    try {
      // Per-request options only — never mutate the shared Dio's global
      // options/headers, since every feature reuses the same instance.
      final response = await _dio.request(
        endPoint,
        data: formData ?? body,
        queryParameters: queryParameters,
        options: dio.Options(
          method: method.value,
          headers: headers,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        return Right(response.data);
      }
      return Left(_mapResponse(response.statusCode, response.data));
    } on dio.DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (_) {
      return const Left(
        ServerFailure("حدث خطأ غير متوقع، يرجى المحاولة لاحقًا."),
      );
    }
  }

  Failure _mapDioException(dio.DioException error) {
    switch (error.type) {
      case dio.DioExceptionType.connectionTimeout:
      case dio.DioExceptionType.sendTimeout:
      case dio.DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          "انتهت مهلة الاتصال، يرجى المحاولة لاحقًا.",
        );
      case dio.DioExceptionType.connectionError:
      case dio.DioExceptionType.unknown:
        return const NetworkFailure(
          "خطأ في الاتصال، يرجى التحقق من اتصالك بالإنترنت.",
        );
      case dio.DioExceptionType.cancel:
        return const ServerFailure("تم إلغاء الطلب.");
      case dio.DioExceptionType.badResponse:
        return _mapResponse(error.response?.statusCode, error.response?.data);
      default:
        return const ServerFailure("حدث خطأ غير معروف.");
    }
  }

  /// Maps a non-2xx status code to a [Failure], preferring the server-provided
  /// message (`message` or `error`) when the body is a map.
  Failure _mapResponse(int? statusCode, dynamic data) {
    final serverMessage =
        data is Map ? (data['message'] ?? data['error'])?.toString() : null;

    switch (statusCode) {
      case 400:
      case 422:
        return ServerFailure(serverMessage ?? "طلب غير صالح.");
      case 401:
        // The interceptor already tried to refresh / redirect to /login.
        return AuthFailure(serverMessage ?? "انتهت الجلسة، يرجى تسجيل الدخول.");
      case 403:
        return const AuthFailure("ليس لديك إذن للوصول إلى هذا المورد.");
      case 404:
        return const ServerFailure("تعذر العثور على المورد المطلوب.");
      case 405:
        return const ServerFailure("طريقة الطلب غير مسموح بها.");
      case 500:
        return const ServerFailure("حدث خطأ في الخادم، يرجى المحاولة لاحقًا.");
      default:
        return ServerFailure(
          serverMessage ?? "حدث خطأ في الخادم، يرجى المحاولة لاحقًا.",
        );
    }
  }
}
