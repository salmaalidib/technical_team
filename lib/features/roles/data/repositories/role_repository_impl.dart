import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_by_department.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_data_source.dart';
import '../models/role_assignment_model.dart';
import '../models/role_by_department_model.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDataSource remote;

  RoleRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, List<RoleAssignment>>> getRoles() async {
    final result = await remote.getRoles();
    return result.fold<Either<Failure, List<RoleAssignment>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) =>
                  RoleAssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الأدوار.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, RoleAssignment>> createRole({
    required String name,
    required String code,
    required int organizationId,
    required int departmentId,
  }) async {
    final result = await remote.createRole({
      'name': name.trim(),
      'code': code.trim(),
      'organization_id': organizationId,
      'department_id': departmentId,
    });
    return result.fold<Either<Failure, RoleAssignment>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            RoleAssignmentModel.fromJson(
                _payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, RoleAssignment>> toggleStatus(int id) async {
    final result = await remote.toggleStatus(id);
    return result.fold<Either<Failure, RoleAssignment>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            RoleAssignmentModel.fromJson(
                _payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر تحديث حالة الدور.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<RoleByDepartment>>> getRolesByDepartment(
    int departmentId,
  ) async {
    final result = await remote.getRolesByDepartment(departmentId);
    return result.fold<Either<Failure, List<RoleByDepartment>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) =>
                  RoleByDepartmentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة أدوار القسم.'));
        }
      },
    );
  }
}
