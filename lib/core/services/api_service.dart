import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';

import '../enums/api_method.dart';
import '../router/app_router.dart';
import '../storage/secure_storage_service.dart';
import 'api_const.dart';

class ApiService {
  static ApiService? _instance;
  late dio.Dio _dio;
  late dio.BaseOptions options;

  static const ApiConstants apiConstants = ApiConstants();
  static const EndPoints endPoints = EndPoints();

  final SecureStorageService _storage = SecureStorageService();

  ApiService._() {
    options = dio.BaseOptions(
      baseUrl: apiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => (status ?? double.infinity) <= 500,
    );
    _dio = dio.Dio(options);

    if (!kReleaseMode) {
      _dio.interceptors.add(dio.LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ));
    }
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _checkInternetConnection() async => true;

  Future<Either<String?, dynamic>> makeRequest({
    required ApiMethod method,
    required String endPoint,
    Map<String, dynamic>? body,
    dio.FormData? formData,
    Map<String, dynamic>? headers,
    bool showSnackBarOnError = true,
  }) async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      return Left("الرجاء التحقق من اتصالك بالإنترنت.");
    }

    _dio.options = _dio.options.copyWith(method: method.value);
    _dio.options.headers = await getHeaders();
    if (headers != null) _dio.options.headers.addAll(headers);

    try {
      final response = await _dio.request(endPoint, data: formData ?? body);
      final apiResponse = handleApiError(response, showSnackBarOnError);
      return apiResponse.status == ApiResponseStatus.failure
          ? Left(apiResponse.message)
          : Right(apiResponse.data);
    } catch (e) {
      return Left("حدث خطأ غير متوقع، يرجى المحاولة لاحقًا.");
    }
  }

  ApiResponse handleApiError(dynamic error, bool showSnackBarOnError) {
    if (error is dio.DioException) {
      switch (error.type) {
        case dio.DioExceptionType.connectionTimeout:
        case dio.DioExceptionType.sendTimeout:
        case dio.DioExceptionType.receiveTimeout:
          return ApiResponse.failure(
              "انتهت مهلة الاتصال، يرجى المحاولة لاحقًا.");
        case dio.DioExceptionType.badResponse:
          return _handleResponseError(error.response, showSnackBarOnError);
        case dio.DioExceptionType.cancel:
          return ApiResponse.failure("تم إلغاء الطلب.");
        case dio.DioExceptionType.connectionError:
        case dio.DioExceptionType.unknown:
          return ApiResponse.failure(
              "خطأ في الاتصال، يرجى التحقق من اتصالك بالإنترنت.");
        default:
          return ApiResponse.failure("خطأ غير معروف.");
      }
    } else if (error is dio.Response) {
      return _handleResponseError(error, showSnackBarOnError);
    } else {
      return ApiResponse.failure("حدث خطأ غير متوقع، يرجى المحاولة لاحقًا.");
    }
  }

  ApiResponse _handleResponseError(
      dio.Response? response, bool showSnackBarOnError) {
    if (response == null) {
      return ApiResponse.failure("حدث خطأ غير متوقع، يرجى المحاولة لاحقًا.");
    }

    switch (response.statusCode) {
      case 200:
      case 201:
      case 203:
        return ApiResponse.success(response.data);
      case 400:
        return ApiResponse.failure(response.data['error'] ?? "طلب غير صالح.");
      case 401:
        AppRouter.router.go('/login');
        return ApiResponse.failure(response.data['message']);
      case 422:
        return ApiResponse.failure(response.data['message']);
      case 403:
        return ApiResponse.failure("ليس لديك إذن للوصول إلى هذا المورد.");
      case 404:
        return ApiResponse.failure("تعذر العثور على المورد المطلوب.");
      case 405:
        return ApiResponse.failure("طريقة الطلب غير مسموح بها.");
      case 500:
        return ApiResponse.failure("حدث خطأ في الخادم، يرجى المحاولة لاحقًا.");
      default:
        return ApiResponse.failure("حدث خطأ في الخادم، يرجى المحاولة لاحقًا.");
    }
  }
}

class ApiResponse {
  final ApiResponseStatus status;
  final dynamic data;
  final String? message;

  ApiResponse.success(this.data)
      : status = ApiResponseStatus.success,
        message = null;

  ApiResponse.failure(this.message)
      : status = ApiResponseStatus.failure,
        data = null;
}

enum ApiResponseStatus { success, failure }
