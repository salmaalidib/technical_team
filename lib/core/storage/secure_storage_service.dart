import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = "token";
  static const _refreshTokenKey = "refresh_token";

  // ===== Access token =====
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ===== Refresh token =====
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // ===== Both tokens =====
  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await saveToken(token);
    await saveRefreshToken(refreshToken);
  }

  /// Wipe all auth tokens (logout / refresh failure).
  Future<void> clear() async {
    await deleteToken();
    await deleteRefreshToken();
  }
}
