import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All API endpoints used across the app.
class EndPoints {
  const EndPoints();

  /// auth
  String get login => 'api/auth/login';
  String get verifyOtp => 'api/auth/verify-otp/login';
  String get logout => 'api/auth/logout';
}

/// Base API configuration. The base url is read from the loaded
/// environment file (`env/*.env`) so it can change per flavor
/// (dev / stage / prod) without touching the code.
class ApiConstants {
  const ApiConstants();

  String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  String get baseUrlImage => dotenv.env['BASE_URL_IMAGE'] ?? '';

  final int responseTimeout = 60;
  final int requestTimeout = 60;
}
