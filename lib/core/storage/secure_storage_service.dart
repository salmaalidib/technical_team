import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = "token";
  static const _refreshTokenKey = "refresh_token";
  static const _activeOrgKey = "active_organization_id";

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

  // ===== Active organization =====
  // Persisted so the user only picks an organization once. Reads/writes are
  // wrapped because secure storage can throw on web (best-effort browser
  // crypto); on failure we degrade to "no active org" rather than crashing.
  Future<void> saveActiveOrgId(int id) async {
    try {
      await _storage.write(key: _activeOrgKey, value: id.toString());
    } catch (_) {
      // Persistence failed (e.g. web). The in-memory choice still works for
      // this session; it just won't survive a reload.
    }
  }

  Future<int?> getActiveOrgId() async {
    try {
      final raw = await _storage.read(key: _activeOrgKey);
      return raw == null ? null : int.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteActiveOrgId() async {
    try {
      await _storage.delete(key: _activeOrgKey);
    } catch (_) {
      // Best effort.
    }
  }

  /// Wipe all auth tokens and the active-organization choice
  /// (logout / refresh failure).
  Future<void> clear() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteActiveOrgId();
  }
}
