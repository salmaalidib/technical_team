import '../../domain/entities/auth_response.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthResponse {

  AuthResponseModel({
    required super.user,
    required super.roles,
    required super.token,
    required super.refreshToken,
  });

  factory AuthResponseModel.fromJson(
  Map<String, dynamic> json,
) {
  final data = json['data'] as Map<String, dynamic>;

  return AuthResponseModel(
    user: UserModel.fromJson(data['user']),
    roles: List<int>.from(data['roles'] ?? []),
    token: data['token'] ?? '',
    refreshToken: data['refreshToken'] ?? '',
  );
}
}