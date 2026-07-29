import 'package:dartz/dartz.dart';

import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the role-assignment endpoints. Error mapping lives in
/// [ApiService]; methods return the raw decoded body on the right.
class RoleRemoteDataSource {
  final ApiService api;

  RoleRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getRoles() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.roles,
    );
  }

  Future<Either<Failure, dynamic>> createRole(Map<String, dynamic> body) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.roles,
      body: body,
    );
  }

  Future<Either<Failure, dynamic>> toggleStatus(int id) {
    return api.makeRequest(
      method: ApiMethod.patch,
      endPoint: _endPoints.roleToggleStatus(id),
    );
  }

  Future<Either<Failure, dynamic>> getRolesByDepartment(int departmentId) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.rolesByDepartment(departmentId),
    );
  }

  // ===== permissions =====

  /// All permissions in the system — the checkbox source for the role form.
  Future<Either<Failure, dynamic>> getPermissions() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.permissions,
    );
  }

  /// Permissions currently attached to the (org, dept, role) triple.
  Future<Either<Failure, dynamic>> getRolePermissions({
    required int organizationId,
    required int departmentId,
    required int roleId,
  }) {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.rolePermissions,
      queryParameters: {
        'organization_id': organizationId,
        'department_id': departmentId,
        'role_id': roleId,
      },
    );
  }

  /// POST adds to the existing set; PUT replaces it wholesale (and accepts an
  /// empty list to clear every permission).
  Future<Either<Failure, dynamic>> saveRolePermissions({
    required Map<String, dynamic> body,
    required bool replace,
  }) {
    return api.makeRequest(
      method: replace ? ApiMethod.put : ApiMethod.post,
      endPoint: _endPoints.rolePermissions,
      body: body,
    );
  }
}
