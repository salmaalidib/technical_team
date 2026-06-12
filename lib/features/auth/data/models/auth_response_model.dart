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
  // Tolerate the unified envelope `{ data: {...} }` as well as a flat body, and
  // never crash on a missing `data`/`user` — fall back to empty maps so the
  // nested models apply their own field-level defaults.
  final data = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json;
  final user = data['user'] is Map
      ? Map<String, dynamic>.from(data['user'] as Map)
      : <String, dynamic>{};

  return AuthResponseModel(
    user: UserModel.fromJson(user),
    roles: List<int>.from(data['roles'] ?? []),
    token: data['token'] ?? '',
    refreshToken: data['refreshToken'] ?? '',
  );
}
}