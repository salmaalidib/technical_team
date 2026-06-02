import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../../institutions/domain/usecases/get_institutions_usecase.dart';
import '../../domain/usecases/create_role_usecase.dart';
import '../../domain/usecases/get_roles_usecase.dart';
import '../../domain/usecases/toggle_role_status_usecase.dart';
import 'roles_event.dart';
import 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  final GetRolesUseCase getRoles;
  final CreateRoleUseCase createRole;
  final ToggleRoleStatusUseCase toggleStatus;

  /// Reused across features: organizations come from `institutions`, the
  /// department options come from `departments`.
  final GetInstitutionsUseCase getOrganizations;
  final GetLeafDepartmentsUseCase getLeafDepartments;

  RolesBloc({
    required this.getRoles,
    required this.createRole,
    required this.toggleStatus,
    required this.getOrganizations,
    required this.getLeafDepartments,
  }) : super(const RolesState()) {
    on<LoadRoles>(_onLoad);
    on<LoadLeafDepartments>(_onLoadLeaves);
    on<CreateRoleRequested>(_onCreate);
    on<ToggleRoleStatus>(_onToggle);
  }

  Future<void> _onLoad(LoadRoles event, Emitter<RolesState> emit) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final rolesResult = await getRoles();

    await rolesResult.fold(
      (failure) async => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (roles) async {
        final organizationsResult = await getOrganizations();
        final organizations =
            organizationsResult.getOrElse(() => state.organizations);

        emit(state.copyWith(
          status: RequestStatus.success,
          roles: roles,
          organizations: organizations,
          error: null,
        ));
      },
    );
  }

  Future<void> _onLoadLeaves(
    LoadLeafDepartments event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(
      leafStatus: RequestStatus.loading,
      leafOrgId: event.organizationId,
      leafDepartments: const [],
    ));

    final result = await getLeafDepartments(event.organizationId);

    result.fold(
      (failure) => emit(state.copyWith(
        leafStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (leaves) => emit(state.copyWith(
        leafStatus: RequestStatus.success,
        leafDepartments: leaves,
      )),
    );
  }

  Future<void> _onCreate(
    CreateRoleRequested event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createRole(
      name: event.name,
      code: event.code,
      organizationId: event.organizationId,
      departmentId: event.departmentId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadRoles());
      },
    );
  }

  Future<void> _onToggle(
    ToggleRoleStatus event,
    Emitter<RolesState> emit,
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
        final roles = state.roles
            .map((r) =>
                r.id == updated.id ? r.copyWith(isActive: updated.isActive) : r)
            .toList();

        emit(state.copyWith(
          roles: roles,
          togglingIds: toggling,
        ));
      },
    );
  }
}
