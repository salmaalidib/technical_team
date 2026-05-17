import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthResponse {

  AuthResponseModel({
    required super.user,
    required super.roles,
    required super.token,
  });

  factory AuthResponseModel.fromJson(
  Map<String, dynamic> json,
) {
  final data = json['data'] as Map<String, dynamic>;

  return AuthResponseModel(
    user: UserModel.fromJson(data['user']),
    roles: List<int>.from(data['roles'] ?? []),
    token: data['token'] ?? '',
  );
}
}