import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // macOS: the default Data Protection Keychain requires the
  // keychain-access-groups entitlement, which the manually-signed Debug build
  // cannot carry (errSecMissingEntitlement -34018 on every write). The legacy
  // file-based login keychain needs no entitlement, so use it instead.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

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
  // Stored in SharedPreferences (not secure storage): the org id is a
  // non-sensitive integer, and flutter_secure_storage does NOT persist
  // reliably on web — its value is lost across a page reload. SharedPreferences
  // maps to localStorage on web and durable native storage elsewhere, so the
  // user's organization choice survives a reload on every platform.
  Future<void> saveActiveOrgId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeOrgKey, id);
  }

  Future<int?> getActiveOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_activeOrgKey);
    if (id != null) return id;

    // One-time migration: pick up an id previously stored in secure storage
    // (e.g. on desktop before this change) and move it to SharedPreferences.
    try {
      final raw = await _storage.read(key: _activeOrgKey);
      final migrated = raw == null ? null : int.tryParse(raw);
      if (migrated != null) {
        await prefs.setInt(_activeOrgKey, migrated);
        await _storage.delete(key: _activeOrgKey);
      }
      return migrated;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteActiveOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrgKey);

    // Also clear any legacy value left in secure storage.
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
