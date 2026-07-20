import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Thin remote contract for the auth endpoints. It only chooses the endpoint
/// and request body; all error mapping lives in [ApiService], so every method
/// returns `Either<Failure, dynamic>` (the raw decoded body on the right).
class AuthRemoteDataSource {
  final ApiService api;

  AuthRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> login(
    String userName,
    String password,
  ) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.login,
      body: {
        'userName': userName.trim(),
        'password': password.trim(),
      },
    );
  }

  Future<Either<Failure, dynamic>> verifyOtp({
    required String sessionId,
    required String otp,
  }) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.verifyLoginOtp,
      body: {
        'session_id': sessionId,
        'otp': otp.trim(),
      },
    );
  }

  Future<Either<Failure, dynamic>> logout(String refreshToken) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.logout,
      body: {'refreshToken': refreshToken},
    );
  }
}
