import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/create_institution_usecase.dart';
import '../../domain/usecases/create_location_usecase.dart';
import '../../domain/usecases/get_institutions_usecase.dart';
import '../../domain/usecases/get_locations_usecase.dart';
import '../../domain/usecases/get_type_locations_usecase.dart';
import '../../domain/usecases/create_type_location_usecase.dart';
import 'institutions_event.dart';
import 'institutions_state.dart';

class InstitutionsBloc extends Bloc<InstitutionsEvent, InstitutionsState> {
  final GetInstitutionsUseCase getInstitutions;
  final GetLocationsUseCase getLocations;
  final CreateInstitutionUseCase createInstitution;
  final CreateLocationUseCase createLocation;
  final GetTypeLocationsUseCase getTypeLocations;
  final CreateTypeLocationUseCase createTypeLocation;

  InstitutionsBloc({
    required this.getInstitutions,
    required this.getLocations,
    required this.createInstitution,
    required this.createLocation,
    required this.getTypeLocations,
    required this.createTypeLocation,
  }) : super(const InstitutionsState()) {
    on<LoadInstitutions>(_onLoad);
    on<CreateInstitutionRequested>(_onCreate);
    on<CreateLocationRequested>(_onCreateLocation);
    on<CreateTypeLocationRequested>(_onCreateTypeLocation);
    on<NavigateToChildren>(_onNavigateToChildren);
    on<NavigateToCrumb>(_onNavigateToCrumb);
    on<SearchChanged>(_onSearchChanged);
    on<PageChanged>(_onPageChanged);
    on<PageSizeChanged>(_onPageSizeChanged);
  }

  Future<void> _onLoad(
    LoadInstitutions event,
    Emitter<InstitutionsState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final institutionsResult = await getInstitutions();

    await institutionsResult.fold(
      (failure) async => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (institutions) async {
        // Locations are only needed for the create form — a failure here
        // shouldn't block showing the list.
        final locationsResult = await getLocations();
        final locations = locationsResult.getOrElse(() => state.locations);

        final typesResult = await getTypeLocations();
        final typeLocations =
            typesResult.getOrElse(() => state.typeLocations);

        emit(state.copyWith(
          status: RequestStatus.success,
          institutions: institutions,
          locations: locations,
          typeLocations: typeLocations,
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
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createInstitution(
      name: event.name,
      parentId: event.parentId,
      locationId: event.locationId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadInstitutions());
      },
    );
  }

  void _onNavigateToChildren(
    NavigateToChildren event,
    Emitter<InstitutionsState> emit,
  ) {
    emit(state.copyWith(
      breadcrumb: [
        ...state.breadcrumb,
        InstitutionCrumb(id: event.parentId, name: event.parentName),
      ],
      searchQuery: '',
      currentPage: 1,
    ));
  }

  void _onNavigateToCrumb(
    NavigateToCrumb event,
    Emitter<InstitutionsState> emit,
  ) {
    // index == -1 -> root level, otherwise keep crumbs up to and including it.
    final trail = event.index < 0
        ? const <InstitutionCrumb>[]
        : state.breadcrumb.sublist(0, event.index + 1);

    emit(state.copyWith(
      breadcrumb: trail,
      searchQuery: '',
      currentPage: 1,
    ));
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<InstitutionsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query, currentPage: 1));
  }

  void _onPageChanged(
    PageChanged event,
    Emitter<InstitutionsState> emit,
  ) {
    emit(state.copyWith(currentPage: event.page));
  }

  void _onPageSizeChanged(
    PageSizeChanged event,
    Emitter<InstitutionsState> emit,
  ) {
    emit(state.copyWith(pageSize: event.size, currentPage: 1));
  }

  Future<void> _onCreateLocation(
    CreateLocationRequested event,
    Emitter<InstitutionsState> emit,
  ) async {
    emit(state.copyWith(
      locationFormStatus: FormStatus.submitting,
      locationFormError: null,
    ));

    final result = await createLocation(
      name: event.name,
      typeLocationId: event.typeLocationId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        locationFormStatus: FormStatus.failure,
        locationFormError: failure.message,
      )),
      (created) async {
        // Refresh the locations list so the new one is available in the
        // dropdown. A failure to reload shouldn't fail the create.
        final locationsResult = await getLocations();
        final locations = locationsResult.getOrElse(
          () => [...state.locations, created],
        );
        emit(state.copyWith(
          locationFormStatus: FormStatus.success,
          locations: locations,
        ));
      },
    );
  }

  Future<void> _onCreateTypeLocation(
    CreateTypeLocationRequested event,
    Emitter<InstitutionsState> emit,
  ) async {
    emit(state.copyWith(
      typeLocationFormStatus: FormStatus.submitting,
      typeLocationFormError: null,
    ));

    final result = await createTypeLocation(name: event.name);

    await result.fold(
      (failure) async => emit(state.copyWith(
        typeLocationFormStatus: FormStatus.failure,
        typeLocationFormError: failure.message,
      )),
      (created) async {
        // Reload so the list stays server-ordered; fall back to appending the
        // created one so the caller can still select it.
        final typesResult = await getTypeLocations();
        final typeLocations = typesResult.getOrElse(
          () => [...state.typeLocations, created],
        );
        emit(state.copyWith(
          typeLocationFormStatus: FormStatus.success,
          typeLocations: typeLocations,
        ));
      },
    );
  }
}
