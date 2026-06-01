import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, AuthResponse>> call({
    required String sessionId,
    required String otp,
  }) {
    return repository.verifyOtp(sessionId: sessionId, otp: otp);
  }
}
