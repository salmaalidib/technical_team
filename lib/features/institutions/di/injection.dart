import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/institution_remote_data_source.dart';
import '../data/repositories/institution_repository_impl.dart';
import '../domain/repositories/institution_repository.dart';
import '../domain/usecases/create_institution_usecase.dart';
import '../domain/usecases/create_location_usecase.dart';
import '../domain/usecases/get_institutions_usecase.dart';
import '../domain/usecases/get_locations_usecase.dart';
import '../domain/usecases/get_type_locations_usecase.dart';
import '../domain/usecases/create_type_location_usecase.dart';
import '../presentation/bloc/institutions_bloc.dart';

Future<void> setupInstitutionsInjection() async {
  if (!getIt.isRegistered<InstitutionRemoteDataSource>()) {
    getIt.registerLazySingleton<InstitutionRemoteDataSource>(
      () => InstitutionRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<InstitutionRepository>()) {
    getIt.registerLazySingleton<InstitutionRepository>(
      () => InstitutionRepositoryImpl(getIt<InstitutionRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetInstitutionsUseCase>()) {
    getIt.registerLazySingleton<GetInstitutionsUseCase>(
      () => GetInstitutionsUseCase(getIt<InstitutionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetLocationsUseCase>()) {
    getIt.registerLazySingleton<GetLocationsUseCase>(
      () => GetLocationsUseCase(getIt<InstitutionRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateInstitutionUseCase>()) {
    getIt.registerLazySingleton<CreateInstitutionUseCase>(
      () => CreateInstitutionUseCase(getIt<InstitutionRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateLocationUseCase>()) {
    getIt.registerLazySingleton<CreateLocationUseCase>(
      () => CreateLocationUseCase(getIt<InstitutionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTypeLocationsUseCase>()) {
    getIt.registerLazySingleton<GetTypeLocationsUseCase>(
      () => GetTypeLocationsUseCase(getIt<InstitutionRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateTypeLocationUseCase>()) {
    getIt.registerLazySingleton<CreateTypeLocationUseCase>(
      () => CreateTypeLocationUseCase(getIt<InstitutionRepository>()),
    );
  }

  getIt.registerFactory<InstitutionsBloc>(
    () => InstitutionsBloc(
      getInstitutions: getIt<GetInstitutionsUseCase>(),
      getLocations: getIt<GetLocationsUseCase>(),
      createInstitution: getIt<CreateInstitutionUseCase>(),
      createLocation: getIt<CreateLocationUseCase>(),
      getTypeLocations: getIt<GetTypeLocationsUseCase>(),
      createTypeLocation: getIt<CreateTypeLocationUseCase>(),
    ),
  );
}
