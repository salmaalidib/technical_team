import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<Response> login(
    String userName,
    String password,
  ) async {

    print("USERNAME: $userName");
    print("PASSWORD: $password");

    final response = await dio.post(
      '/api/auth/login',

      data: {
        "userName": userName.trim(),
        "password": password.trim(),
      },

      options: Options(
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    print(response.data);

    return response;
  }

  Future<Response> verifyOtp({
  required String sessionId,
  required String otp,
}) async {

  final response = await dio.post(
    '/api/auth/verify-otp/login',

    data: {
      "session_id": sessionId,
      "otp": otp,
    },

    options: Options(
      headers: {
        "accept": "application/json",
        "Content-Type": "application/json",
      },
    ),
  );

  print(response.data);

  return response;
}
}