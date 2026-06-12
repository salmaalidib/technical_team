import '../../domain/entities/login_response.dart';

class LoginResponseModel extends LoginResponse {

  LoginResponseModel({
    required super.sessionId,
    required super.message,
  });

  factory LoginResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // Tolerate the unified envelope `{ data: { session_id, message } }` as well
    // as a flat `{ session_id, message }` body, and never crash on a missing
    // field — a null session_id surfaces as an empty string the caller can check.
    final data = json['data'] is Map ? json['data'] as Map : json;

    return LoginResponseModel(
      sessionId: (data['session_id'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
    );
  }
}