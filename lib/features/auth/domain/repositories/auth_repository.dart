import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../entities/login_response.dart';

abstract class AuthRepository {
  Future<Either<Failure, LoginResponse>> login({
    required String userName,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String sessionId,
    required String otp,
  });

  Future<Either<Failure, Unit>> logout();
}
