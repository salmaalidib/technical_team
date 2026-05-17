import '../entities/login_response.dart';
import '../entities/auth_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String userName,
    required String password,
  });

   Future<AuthResponse> verifyOtp({
    required String sessionId,
    required String otp,
  });
}