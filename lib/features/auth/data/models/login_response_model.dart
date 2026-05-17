import '../../domain/entities/login_response.dart';

class LoginResponseModel extends LoginResponse {

  LoginResponseModel({
    required super.sessionId,
    required super.message,
  });

  factory LoginResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {

    final data = json['data'];

    return LoginResponseModel(
      sessionId: data['session_id'],
      message: data['message'],
    );
  }
}