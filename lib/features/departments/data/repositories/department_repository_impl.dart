import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../institutions/data/models/institution_model.dart';
import '../../../institutions/domain/entities/institution.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_overview.dart';
import '../../domain/entities/leaf_department.dart';
import '../../domain/repositories/department_repository.dart';
import '../datasources/department_remote_data_source.dart';
import '../models/department_model.dart';
import '../models/department_overview_model.dart';
import '../models/leaf_department_model.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  final DepartmentRemoteDataSource remote;

  DepartmentRepositoryImpl(this.remote);

  /// Unwraps the `{ success, message, data }` envelope returned by [ApiService].
  static dynamic _payload(dynamic body) =>
      body is Map<String, dynamic> ? body['data'] : body;

  @override
  Future<Either<Failure, List<Department>>> getDepartments() async {
    final result = await remote.getDepartments();
    return result.fold<Either<Failure, List<Department>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الأقسام.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<Institution>>> getOrganizations() async {
    final result = await remote.getOrganizations();
    return result.fold<Either<Failure, List<Institution>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) => InstitutionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة المؤسسات.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<LeafDepartment>>> getLeafDepartments(
    int organizationId,
  ) async {
    final result = await remote.getLeaves(organizationId);
    return result.fold<Either<Failure, List<LeafDepartment>>>(
      (failure) => Left(failure),
      (body) {
        try {
          final list = (_payload(body) as List)
              .map((e) =>
                  LeafDepartmentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(list);
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة قائمة الأقسام.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, DepartmentOverview>> getOverview(int id) async {
    final result = await remote.getOverview(id);
    return result.fold<Either<Failure, DepartmentOverview>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            DepartmentOverviewModel.fromJson(
              _payload(body) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة بيانات القسم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Department>> createDepartment({
    required String name,
    required int organizationId,
    int? parentId,
  }) async {
    final result = await remote.createDepartment({
      'name': name.trim(),
      'organization_id': organizationId,
      if (parentId != null) 'parent_id': parentId,
    });
    return result.fold<Either<Failure, Department>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            DepartmentModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر قراءة استجابة الخادم.'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Department>> toggleStatus(int id) async {
    final result = await remote.toggleStatus(id);
    return result.fold<Either<Failure, Department>>(
      (failure) => Left(failure),
      (body) {
        try {
          return Right(
            DepartmentModel.fromJson(_payload(body) as Map<String, dynamic>),
          );
        } catch (_) {
          return const Left(ServerFailure('تعذّر تحديث حالة القسم.'));
        }
      },
    );
  }
}
