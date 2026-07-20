import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_response_model.dart';
import '../models/login_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  AuthRepositoryImpl(this.remote, this.storage);

  @override
  Future<Either<Failure, LoginResponse>> login({
    required String userName,
    required String password,
  }) async {
    final result = await remote.login(userName, password);
    return result.fold<Either<Failure, LoginResponse>>(
      (failure) => Left(failure),
      (data) {
        try {
          return Right(
            LoginResponseModel.fromJson(data as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String sessionId,
    required String otp,
  }) async {
    final result = await remote.verifyOtp(sessionId: sessionId, otp: otp);
    return result.fold<Future<Either<Failure, AuthResponse>>>(
      (failure) async => Left(failure),
      (data) async {
        try {
          final authResponse =
              AuthResponseModel.fromJson(data as Map<String, dynamic>);

          // Persisting the session is a data-layer concern, so it lives here
          // (not in the bloc). Any storage failure becomes a Left(Failure),
          // keeping ALL error handling inside the Either flow.
          await storage.saveTokens(
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
          );

          return Right(authResponse);
        } catch (e, st) {
          // TEMP DIAGNOSTIC: surface the swallowed error so we can see WHY a
          // 200 response still fails login (suspected: keychain saveTokens).
          // ignore: avoid_print
          print('[verifyOtp] swallowed error: $e\n$st');
          return const Left(
            ServerFailure('تعذّر إكمال تسجيل الدخول، يرجى المحاولة لاحقًا.'),
          );
        }
      },
    );
  }
}
