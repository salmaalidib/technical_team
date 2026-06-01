import 'user.dart';

class AuthResponse {
  final User user;
  final List<int> roles;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.roles,
    required this.token,
    required this.refreshToken,
  });
}