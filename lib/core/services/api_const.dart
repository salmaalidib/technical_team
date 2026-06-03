import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All API endpoints used across the app.
///
/// Mirrors the backend routes mounted in `DirectorateOFEducation/src/app.js`.
/// The backend issues a short-lived access token plus a rotating refresh
/// token. The client refreshes via [refresh] on 401 and revokes the refresh
/// token via [logout].
///
/// Paths are relative (no leading slash); Dio resolves them against
/// [ApiConstants.baseUrl].
class EndPoints {
  const EndPoints();

  // ===== auth — password + OTP flow (2 steps) =====
  String get login => 'api/auth/login'; // step 1 → session_id + sends OTP
  String get verifyLoginOtp =>
      'api/auth/verify-otp/login'; // step 2 → token + refreshToken + user + roles

  // ===== auth — token lifecycle =====
  String get refresh =>
      'api/auth/refresh'; // { refreshToken } → { token, refreshToken }
  String get logout =>
      'api/auth/logout'; // { refreshToken } → revokes refresh token

  // ===== organization (bearer token required) =====
  String get organizations => 'api/organization'; // GET list · POST create
  String organizationById(Object id) => 'api/organization/$id'; // GET by id

  // ===== department (bearer token required) =====
  String get departments => 'api/department'; // GET list · POST create
  String departmentById(Object id) => 'api/department/$id'; // GET by id
  String departmentOverview(Object id) =>
      'api/department/$id/overview'; // GET manager/employees/sections/transactions
  String departmentToggleStatus(Object id) =>
      'api/department/$id/toggle-status'; // PATCH is_active
  String departmentLeavesByOrg(Object orgId) =>
      'api/department/by-organization/$orgId/leaves';

  // ===== role (bearer token required) =====
  String get roles => 'api/role'; // GET list · POST create
  String roleToggleStatus(Object id) =>
      'api/role/$id/toggle-status'; // PATCH is_active

  // ===== requirements: dynamic fields (bearer token required) =====
  String get fields => 'api/fields'; // GET list · POST create
  String fieldById(Object id) => 'api/fields/$id'; // PUT update (versioned)

  // ===== requirements: file definitions (bearer token required) =====
  String get files => 'api/files'; // GET list · POST create
  String fileById(Object id) => 'api/files/$id'; // PUT update (versioned)

  // ===== location (bearer token required) =====
  String get locations => 'api/location'; // GET list
}

/// Base API configuration. The base url is read from the loaded environment
/// file (`env/*.env`) so it can change per flavor (dev / stage / prod)
/// without touching the code.
class ApiConstants {
  const ApiConstants();

  String get baseUrl => dotenv.env['BASE_URL'] ?? '';
}
