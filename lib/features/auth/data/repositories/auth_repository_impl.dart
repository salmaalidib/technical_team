import 'package:technical_team/features/auth/data/models/auth_response_model.dart';
import 'package:technical_team/features/auth/domain/entities/auth_response.dart';

import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  @override
  Future<LoginResponse> login({
    required String userName,
    required String password,
  }) async {

    final response = await remote.login(
      userName,
      password,
    );

    return LoginResponseModel.fromJson(response.data);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String sessionId,
    required String otp,
  }) async {

    final response = await remote.verifyOtp(
      sessionId: sessionId,
      otp: otp,
    );

    return AuthResponseModel.fromJson(response.data);
  }
}