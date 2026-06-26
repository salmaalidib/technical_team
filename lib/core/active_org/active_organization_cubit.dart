import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/institutions/domain/entities/institution.dart';
import '../../features/institutions/domain/usecases/get_institutions_usecase.dart';
import '../di/injection.dart';
import '../enums/request_status.dart';
import '../storage/secure_storage_service.dart';

/// The single source of truth for the user's currently-selected organization.
///
/// Registered as a lazy singleton (see `setupCoreInjection`), so every feature
/// reads the SAME instance. The user picks an organization once after login
/// (see `/select-organization`); the choice is persisted via
/// [SecureStorageService] and reused everywhere instead of a per-form dropdown.
class ActiveOrganizationCubit extends Cubit<ActiveOrgState> {
  final SecureStorageService _storage;

  ActiveOrganizationCubit(this._storage) : super(const ActiveOrgState());

  /// The active organization's id, or null when none is selected yet. Read
  /// synchronously by create dialogs to fill `organization_id` automatically.
  int? get activeOrgId => state.activeOrg?.id;

  bool get hasActiveOrg => state.activeOrg != null;

  /// Loads the organization list once and resolves the persisted selection
  /// against it. Call from the splash (token-present path) so the list is warm
  /// before any feature page opens — feature blocs then never fetch it.
  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading, error: null));

    // The usecase is registered by setupInstitutionsInjection, which runs after
    // core — resolve it lazily here rather than injecting it at construction.
    final result = await getIt<GetInstitutionsUseCase>()();

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (organizations) async {
        final savedId = await _storage.getActiveOrgId();
        Institution? active;
        if (savedId != null) {
          for (final o in organizations) {
            if (o.id == savedId) {
              active = o;
              break;
            }
          }
          // The persisted org no longer exists (deleted / permissions changed):
          // drop the stale id so the user is asked to pick again.
          if (active == null) {
            await _storage.deleteActiveOrgId();
          }
        }

        emit(state.copyWith(
          status: RequestStatus.success,
          organizations: organizations,
          activeOrg: active,
          clearActiveOrg: active == null,
          error: null,
        ));
      },
    );
  }

  /// Persists [org] as the active organization and updates state.
  Future<void> setActive(Institution org) async {
    await _storage.saveActiveOrgId(org.id);
    emit(state.copyWith(activeOrg: org));
  }

  /// Clears the active organization (logout / session end).
  Future<void> clear() async {
    await _storage.deleteActiveOrgId();
    emit(const ActiveOrgState());
  }
}

class ActiveOrgState extends Equatable {
  final List<Institution> organizations;
  final Institution? activeOrg;
  final RequestStatus status;
  final String? error;

  const ActiveOrgState({
    this.organizations = const [],
    this.activeOrg,
    this.status = RequestStatus.initial,
    this.error,
  });

  ActiveOrgState copyWith({
    List<Institution>? organizations,
    Institution? activeOrg,
    bool clearActiveOrg = false,
    RequestStatus? status,
    String? error,
  }) {
    return ActiveOrgState(
      organizations: organizations ?? this.organizations,
      activeOrg: clearActiveOrg ? null : (activeOrg ?? this.activeOrg),
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [organizations, activeOrg, status, error];
}
