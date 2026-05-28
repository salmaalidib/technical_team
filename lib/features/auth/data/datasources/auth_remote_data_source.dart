import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failures.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<Response> login(
    String userName,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/api/auth/login',
        data: {
          'userName': userName.trim(),
          'password': password.trim(),
        },
      );

      return response;
    } catch (e) {
      throw AppException(ErrorHandler.handle(e));
    }
  }

  Future<Response> verifyOtp({
    required String sessionId,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        '/api/auth/verify-otp/login',
        data: {
          'session_id': sessionId,
          'otp': otp.trim(),
        },
      );

      return response;
    } catch (e) {
      throw AppException(ErrorHandler.handle(e));
    }
  }
}