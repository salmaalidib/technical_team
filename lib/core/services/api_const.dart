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
  String rolesByDepartment(Object departmentId) =>
      'api/role/by-department/$departmentId'; // GET roles of a leaf department

  // ===== typeProcess (bearer token required) =====
  String get typeProcesses => 'api/typeProcess'; // GET list · POST create
  String typeProcessById(Object id) =>
      'api/typeProcess/$id'; // PUT update is_active

  // ===== process definitions / builder (المسؤول التقني) =====
  String get processDefinitionCreate =>
      'api/process_definitions/create'; // POST multipart (BPMN + meta)
  String get processDefinitionReviewQueue =>
      'api/process_definitions/admin/review-queue'; // GET unapproved/inactive (paginated)
  String get processDefinitionMissingStageConfig =>
      'api/process_definitions/admin/missing-stage-config'; // GET processes with stages missing config
  String processDefinitionsByType(Object typeId) =>
      'api/process_definitions/admin/type/$typeId'; // GET all by type (0 = all), paginated
  String processDefinitionDetails(Object id) =>
      'api/process_definitions/$id/details'; // GET details + validation
  String processDefinitionReview(Object id) =>
      'api/process_definitions/$id/review'; // POST { decision: APPROVE | REJECT }

  // ===== stage config (المسؤول التقني) =====
  String get stageConfigCreate =>
      'api/stage_config/create'; // POST bulk stage configs

  // ===== typeDoc — document types (bearer token required) =====
  String get typeDocs => 'api/typeDoc'; // GET list · POST create
  String typeDocById(Object id) =>
      'api/typeDoc/$id'; // PUT update (name / is_active)

  // ===== document templates (المسؤول التقني) =====
  String get documentTemplates =>
      'api/document-templates'; // GET active list · POST create (JSON: name + type_doc_id + path + url + config_json)
  String get documentTemplatesExtractFields =>
      'api/document-templates/extract-fields'; // POST multipart (file) → AcroForm fields + path + url
  String documentTemplateById(Object id) =>
      'api/document-templates/$id'; // GET one · PUT update config_json (JSON, versioned)
  String documentTemplateFields(Object id) =>
      'api/document-templates/$id/fields'; // GET extracted AcroForm fields of a saved template

  // ===== requirements: dynamic field widgets (bearer token required) =====
  String get textFields => 'api/text-fields'; // GET list · POST create
  String get radioGroups => 'api/radio-groups'; // GET list · POST create
  String get textDropdowns => 'api/text-dropdowns'; // GET list · POST create
  String get checkLists => 'api/check-lists'; // GET list · POST create
  String get datePickers => 'api/date-pickers'; // GET list · POST create
  String get filePickers => 'api/file-pickers'; // GET list · POST create

  // ===== location (bearer token required) =====
  String get locations => 'api/location'; // GET list

  // ===== employee registration =====
String get registerEmployee => 'api/auth/register/employee/';

  // ===== employees (bearer token required) =====
  String get employees => 'api/employees'; // GET list (paginated + search)
  String employeeById(Object id) =>
      'api/employees/$id'; // GET one · PUT update
}

/// Base API configuration. The base url is read from the loaded environment
/// file (`env/*.env`) so it can change per flavor (dev / stage / prod)
/// without touching the code.
class ApiConstants {
  const ApiConstants();

  String get baseUrl => dotenv.env['BASE_URL'] ?? '';
}
