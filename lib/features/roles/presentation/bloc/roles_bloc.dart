import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../departments/domain/usecases/get_leaf_departments_usecase.dart';
import '../../domain/usecases/create_role_usecase.dart';
import '../../domain/usecases/get_permissions_usecase.dart';
import '../../domain/usecases/get_role_permissions_usecase.dart';
import '../../domain/usecases/get_roles_by_department_usecase.dart';
import '../../domain/usecases/get_roles_usecase.dart';
import '../../domain/usecases/save_role_permissions_usecase.dart';
import '../../domain/usecases/toggle_role_status_usecase.dart';
import 'roles_event.dart';
import 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  final GetRolesUseCase getRoles;
  final CreateRoleUseCase createRole;
  final ToggleRoleStatusUseCase toggleStatus;
  final GetRolesByDepartmentUseCase getRolesByDepartment;

  /// Leaf-department options for the create-role form. The organization is the
  /// user's active one (ActiveOrganizationCubit); the dialog fires the leaf
  /// fetch for it on open, so there's no org dropdown to load a list for.
  final GetLeafDepartmentsUseCase getLeafDepartments;

  /// Permission options for the create form, and the second step that attaches
  /// the chosen ones to the freshly created role.
  final GetPermissionsUseCase getPermissions;
  final SaveRolePermissionsUseCase saveRolePermissions;

  /// Reads the permissions currently attached to a role, to pre-check the
  /// boxes when the edit dialog opens.
  final GetRolePermissionsUseCase getRolePermissions;

  RolesBloc({
    required this.getRoles,
    required this.createRole,
    required this.toggleStatus,
    required this.getLeafDepartments,
    required this.getRolesByDepartment,
    required this.getPermissions,
    required this.saveRolePermissions,
    required this.getRolePermissions,
  }) : super(const RolesState()) {
    on<LoadRoles>(_onLoad);
    on<LoadLeafDepartments>(_onLoadLeaves);
    on<LoadPermissions>(_onLoadPermissions);
    on<CreateRoleRequested>(_onCreate);
    on<ToggleRoleStatus>(_onToggle);
    on<LoadRolesByDepartment>(_onLoadByDepartment);
    on<OpenEditPermissions>(_onOpenEditPermissions);
    on<SaveEditedPermissions>(_onSaveEditedPermissions);
  }

  Future<void> _onLoad(LoadRoles event, Emitter<RolesState> emit) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
      loadedOrgId: event.organizationId,
    ));

    final rolesResult = await getRoles(event.organizationId);

    rolesResult.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (roles) => emit(state.copyWith(
        status: RequestStatus.success,
        roles: roles,
        error: null,
      )),
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

  Future<void> _onLoadPermissions(
    LoadPermissions event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(permissionsStatus: RequestStatus.loading));

    final result = await getPermissions(audience: event.audience);

    result.fold(
      (failure) => emit(state.copyWith(
        permissionsStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (permissions) => emit(state.copyWith(
        permissionsStatus: RequestStatus.success,
        permissions: permissions,
      )),
    );
  }

  /// Creating a role with permissions is two requests: the role first, then the
  /// permission links (which key off the returned `role_id`).
  ///
  /// If the second call fails the role still exists, so this reports success
  /// with a warning instead of a failure — surfacing "failure" would invite a
  /// retry that the backend rejects as a 409 duplicate.
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
      parentId: event.parentId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (role) async {
        String? warning;

        if (event.permissionIds.isNotEmpty) {
          if (role.roleId > 0) {
            final linked = await saveRolePermissions(
              organizationId: event.organizationId,
              departmentId: event.departmentId,
              roleId: role.roleId,
              permissionIds: event.permissionIds,
            );

            warning = linked.fold(
              (failure) => 'تم إنشاء الدور، لكن تعذّر ربط الصلاحيات '
                  '(${failure.message}). أضفها لاحقاً من تعديل الدور.',
              (_) => null,
            );
          } else {
            // No role_id came back, so there is nothing to attach to.
            warning = 'تم إنشاء الدور، لكن تعذّر ربط الصلاحيات لعدم توفّر '
                'معرّف الدور. أضفها لاحقاً من تعديل الدور.';
          }
        }

        emit(state.copyWith(
          formStatus: FormStatus.success,
          partialWarning: warning,
        ));
        // Reload the list the page is showing, not the org the role was created
        // under — they are the same in practice, but the list must stay
        // consistent with what was last loaded.
        add(LoadRoles(state.loadedOrgId ?? event.organizationId));
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

  Future<void> _onLoadByDepartment(
    LoadRolesByDepartment event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(
      byDeptStatus: RequestStatus.loading,
      byDeptId: event.departmentId,
      rolesByDepartment: const [],
    ));

    final result = await getRolesByDepartment(event.departmentId);

    result.fold(
      (failure) => emit(state.copyWith(
        byDeptStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (roles) => emit(state.copyWith(
        byDeptStatus: RequestStatus.success,
        rolesByDepartment: roles,
      )),
    );
  }

  /// Prepares the edit dialog: it needs the full permission list (the checkbox
  /// options) and the role's current permissions (the pre-checked ids). Both
  /// are fetched together; the shared `permissions` list is only reloaded if
  /// it wasn't already fetched by the create form.
  Future<void> _onOpenEditPermissions(
    OpenEditPermissions event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(
      editPermsStatus: RequestStatus.loading,
      editInitialIds: const {},
      editFormStatus: FormStatus.idle,
      editFormError: null,
    ));

    final needFullList = state.permissions.isEmpty ||
        state.permissionsStatus != RequestStatus.success;

    // Full list first (the checkbox options), only if not already loaded.
    if (needFullList) {
      final listResult = await getPermissions();
      final failed = listResult.fold((f) => f.message, (_) => null);
      if (failed != null) {
        emit(state.copyWith(
          editPermsStatus: RequestStatus.failure,
          actionError: failed,
        ));
        return;
      }
      emit(state.copyWith(
        permissionsStatus: RequestStatus.success,
        permissions: listResult.getOrElse(() => const []),
      ));
    }

    // Role's current permissions → pre-checked ids.
    final currentResult = await getRolePermissions(
      organizationId: event.organizationId,
      departmentId: event.departmentId,
      roleId: event.roleId,
    );
    currentResult.fold(
      (failure) => emit(state.copyWith(
        editPermsStatus: RequestStatus.failure,
        actionError: failure.message,
      )),
      (rolePerms) => emit(state.copyWith(
        editPermsStatus: RequestStatus.success,
        editInitialIds: rolePerms.permissionIds.toSet(),
      )),
    );
  }

  /// Saves the edited set with PUT (full replace). An empty list is valid and
  /// clears every permission.
  Future<void> _onSaveEditedPermissions(
    SaveEditedPermissions event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(
      editFormStatus: FormStatus.submitting,
      editFormError: null,
    ));

    final result = await saveRolePermissions(
      organizationId: event.organizationId,
      departmentId: event.departmentId,
      roleId: event.roleId,
      permissionIds: event.permissionIds,
      replace: true,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        editFormStatus: FormStatus.failure,
        editFormError: failure.message,
      )),
      (_) => emit(state.copyWith(editFormStatus: FormStatus.success)),
    );
  }
}
