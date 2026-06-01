import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_institution_usecase.dart';
import '../../domain/usecases/get_institutions_usecase.dart';
import '../../domain/usecases/get_locations_usecase.dart';
import 'institutions_event.dart';
import 'institutions_state.dart';

class InstitutionsBloc extends Bloc<InstitutionsEvent, InstitutionsState> {
  final GetInstitutionsUseCase getInstitutions;
  final GetLocationsUseCase getLocations;
  final CreateInstitutionUseCase createInstitution;

  InstitutionsBloc({
    required this.getInstitutions,
    required this.getLocations,
    required this.createInstitution,
  }) : super(const InstitutionsState()) {
    on<LoadInstitutions>(_onLoad);
    on<CreateInstitutionRequested>(_onCreate);
  }

  Future<void> _onLoad(
    LoadInstitutions event,
    Emitter<InstitutionsState> emit,
  ) async {
    emit(state.copyWith(
      status: InstitutionsStatus.loading,
      error: null,
      formStatus: InstitutionFormStatus.idle,
      formError: null,
    ));

    final institutionsResult = await getInstitutions();

    await institutionsResult.fold(
      (failure) async => emit(state.copyWith(
        status: InstitutionsStatus.failure,
        error: failure.message,
      )),
      (institutions) async {
        // Locations are only needed for the create form — a failure here
        // shouldn't block showing the list.
        final locationsResult = await getLocations();
        final locations = locationsResult.getOrElse(() => state.locations);

        emit(state.copyWith(
          status: InstitutionsStatus.success,
          institutions: institutions,
          locations: locations,
          error: null,
        ));
      },
    );
  }

  Future<void> _onCreate(
    CreateInstitutionRequested event,
    Emitter<InstitutionsState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: InstitutionFormStatus.submitting,
      formError: null,
    ));

    final result = await createInstitution(
      name: event.name,
      parentId: event.parentId,
      locationId: event.locationId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: InstitutionFormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: InstitutionFormStatus.success));
        add(const LoadInstitutions());
      },
    );
  }
}
