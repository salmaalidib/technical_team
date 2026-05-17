import 'user.dart';

class AuthResponse {
  final User user;
  final List<int> roles;
  final String token;

  AuthResponse({
    required this.user,
    required this.roles,
    required this.token,
  });
}