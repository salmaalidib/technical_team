import 'package:dartz/dartz.dart';
import '../../../../core/enums/api_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/api_const.dart';
import '../../../../core/services/api_service.dart';

/// Remote contract for the organization + location endpoints. All error
/// mapping lives in [ApiService]; methods return the raw decoded body on the
/// right of the `Either`.
class InstitutionRemoteDataSource {
  final ApiService api;

  InstitutionRemoteDataSource(this.api);

  static const _endPoints = EndPoints();

  Future<Either<Failure, dynamic>> getInstitutions() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.organizations,
    );
  }

  Future<Either<Failure, dynamic>> getLocations() {
    return api.makeRequest(
      method: ApiMethod.get,
      endPoint: _endPoints.locations,
    );
  }

  Future<Either<Failure, dynamic>> createInstitution(
    Map<String, dynamic> body,
  ) {
    return api.makeRequest(
      method: ApiMethod.post,
      endPoint: _endPoints.organizations,
      body: body,
    );
  }
}
