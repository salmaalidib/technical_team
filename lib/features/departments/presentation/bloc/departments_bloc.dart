import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/department_overview.dart';
import '../../domain/usecases/create_department_usecase.dart';
import '../../domain/usecases/get_department_overview_usecase.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/toggle_department_status_usecase.dart';
import 'departments_event.dart';
import 'departments_state.dart';

class DepartmentsBloc extends Bloc<DepartmentsEvent, DepartmentsState> {
  final GetDepartmentsUseCase getDepartments;
  final GetDepartmentOverviewUseCase getOverview;
  final CreateDepartmentUseCase createDepartment;
  final ToggleDepartmentStatusUseCase toggleStatus;

  DepartmentsBloc({
    required this.getDepartments,
    required this.getOverview,
    required this.createDepartment,
    required this.toggleStatus,
  }) : super(const DepartmentsState()) {
    on<LoadDepartments>(_onLoad);
    on<LoadDepartmentOverview>(_onLoadOverview);
    on<CreateDepartmentRequested>(_onCreate);
    on<ToggleDepartmentStatus>(_onToggle);
    on<NavigateToChildren>(_onNavigateToChildren);
    on<NavigateToCrumb>(_onNavigateToCrumb);
    on<SearchChanged>(_onSearchChanged);
    on<PageChanged>(_onPageChanged);
    on<PageSizeChanged>(_onPageSizeChanged);
  }

  Future<void> _onLoad(
    LoadDepartments event,
    Emitter<DepartmentsState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final departmentsResult = await getDepartments();

    departmentsResult.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (departments) {
        // A reload keeps the user on their current level, but drops any
        // breadcrumb crumb whose department no longer exists.
        final ids = departments.map((d) => d.id).toSet();
        final trimmed = <DepartmentCrumb>[];
        for (final crumb in state.breadcrumb) {
          if (!ids.contains(crumb.id)) break;
          trimmed.add(crumb);
        }

        emit(state.copyWith(
          status: RequestStatus.success,
          departments: departments,
          // A fresh list invalidates the cached overviews.
          overviews: const <int, DepartmentOverview>{},
          error: null,
          breadcrumb: trimmed,
          currentPage: 1,
        ));
      },
    );
  }

  Future<void> _onLoadOverview(
    LoadDepartmentOverview event,
    Emitter<DepartmentsState> emit,
  ) async {
    emit(state.copyWith(
      loadingOverviews: {...state.loadingOverviews, event.id},
      actionError: null,
    ));

    final result = await getOverview(event.id);

    final loading = {...state.loadingOverviews}..remove(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        loadingOverviews: loading,
        actionError: failure.message,
      )),
      (overview) => emit(state.copyWith(
        overviews: {...state.overviews, event.id: overview},
        loadingOverviews: loading,
      )),
    );
  }

  Future<void> _onCreate(
    CreateDepartmentRequested event,
    Emitter<DepartmentsState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createDepartment(
      name: event.name,
      organizationId: event.organizationId,
      parentId: event.parentId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadDepartments());
      },
    );
  }

  Future<void> _onToggle(
    ToggleDepartmentStatus event,
    Emitter<DepartmentsState> emit,
  ) async {
    emit(state.copyWith(
      togglingIds: {...state.togglingIds, event.id},
      actionError: null,
    ));

    final result = await toggleStatus(event.id);

    final toggling = {...state.togglingIds}..remove(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        togglingIds: toggling,
        actionError: failure.message,
      )),
      (updated) {
        final departments = state.departments
            .map((d) =>
                d.id == updated.id ? d.copyWith(isActive: updated.isActive) : d)
            .toList();
        // Drop the stale overview for this department.
        final overviews = {...state.overviews}..remove(event.id);

        emit(state.copyWith(
          departments: departments,
          togglingIds: toggling,
          overviews: overviews,
        ));
      },
    );
  }

  void _onNavigateToChildren(
    NavigateToChildren event,
    Emitter<DepartmentsState> emit,
  ) {
    emit(state.copyWith(
      breadcrumb: [
        ...state.breadcrumb,
        DepartmentCrumb(id: event.parentId, name: event.parentName),
      ],
      searchQuery: '',
      currentPage: 1,
    ));
  }

  void _onNavigateToCrumb(
    NavigateToCrumb event,
    Emitter<DepartmentsState> emit,
  ) {
    // index == -1 → root level, otherwise keep crumbs up to and including it.
    final trail = event.index < 0
        ? const <DepartmentCrumb>[]
        : state.breadcrumb.sublist(0, event.index + 1);

    emit(state.copyWith(
      breadcrumb: trail,
      searchQuery: '',
      currentPage: 1,
    ));
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<DepartmentsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query, currentPage: 1));
  }

  void _onPageChanged(
    PageChanged event,
    Emitter<DepartmentsState> emit,
  ) {
    final page = event.page.clamp(1, state.pageCount);
    emit(state.copyWith(currentPage: page));
  }

  void _onPageSizeChanged(
    PageSizeChanged event,
    Emitter<DepartmentsState> emit,
  ) {
    emit(state.copyWith(pageSize: event.size, currentPage: 1));
  }
}
