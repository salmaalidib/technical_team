import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/app_versions_usecases.dart';
import 'app_versions_event.dart';
import 'app_versions_state.dart';

class AppVersionsBloc extends Bloc<AppVersionsEvent, AppVersionsState> {
  final GetApplicationsUseCase getApplications;
  final UpdateApplicationUseCase updateApplication;
  final GetVersionsUseCase getVersions;
  final CreateVersionUseCase createVersion;
  final UpdateVersionUseCase updateVersion;
  final DeleteVersionUseCase deleteVersion;

  AppVersionsBloc({
    required this.getApplications,
    required this.updateApplication,
    required this.getVersions,
    required this.createVersion,
    required this.updateVersion,
    required this.deleteVersion,
  }) : super(const AppVersionsState()) {
    on<LoadApplications>(_onLoadApplications);
    on<SelectApplication>(_onSelectApplication);
    on<ReloadVersions>(_onReloadVersions);
    on<CreateVersionRequested>(_onCreateVersion);
    on<UpdateVersionRequested>(_onUpdateVersion);
    on<ToggleVersionStatus>(_onToggleStatus);
    on<DeleteVersionRequested>(_onDeleteVersion);
    on<UpdateApplicationRequested>(_onUpdateApplication);
    on<ClearFormFeedback>(_onClearFeedback);
  }

  Future<void> _onLoadApplications(
    LoadApplications event,
    Emitter<AppVersionsState> emit,
  ) async {
    emit(state.copyWith(
      appsStatus: RequestStatus.loading,
      clearAppsError: true,
    ));

    final result = await getApplications();

    await result.fold(
      (failure) async => emit(state.copyWith(
        appsStatus: RequestStatus.failure,
        appsError: failure.message,
      )),
      (applications) async {
        // نبقي التطبيق المختار إن كان لا يزال موجوداً بعد إعادة التحميل، وإلا
        // نختار الأول — حتى لا تفرغ الشاشة بلا سبب ظاهر.
        final stillExists =
            applications.any((app) => app.id == state.selectedAppId);
        final selectedId = stillExists
            ? state.selectedAppId
            : (applications.isEmpty ? null : applications.first.id);

        emit(state.copyWith(
          appsStatus: RequestStatus.success,
          applications: applications,
          selectedAppId: selectedId,
        ));

        if (selectedId != null) {
          await _loadVersionsFor(selectedId, emit);
        }
      },
    );
  }

  Future<void> _onSelectApplication(
    SelectApplication event,
    Emitter<AppVersionsState> emit,
  ) async {
    if (state.selectedAppId == event.appId) return;

    // نُفرغ القائمة فوراً حتى لا تُعرض إصدارات التطبيق السابق تحت اسم الجديد
    // أثناء التحميل.
    emit(state.copyWith(
      selectedAppId: event.appId,
      versions: const [],
      versionsStatus: RequestStatus.loading,
      clearVersionsError: true,
    ));

    await _loadVersionsFor(event.appId, emit);
  }

  Future<void> _onReloadVersions(
    ReloadVersions event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;
    await _loadVersionsFor(appId, emit);
  }

  Future<void> _loadVersionsFor(
    int appId,
    Emitter<AppVersionsState> emit,
  ) async {
    emit(state.copyWith(
      versionsStatus: RequestStatus.loading,
      clearVersionsError: true,
    ));

    final result = await getVersions(appId);

    result.fold(
      (failure) => emit(state.copyWith(
        versionsStatus: RequestStatus.failure,
        versionsError: failure.message,
      )),
      (versions) {
        // ترتيب تنازلي حسب version_code داخل كل منصة — الأحدث أولاً، وهو
        // الترتيب نفسه الذي يعتمده الخادم في اختيار الإصدار المعروض.
        final sorted = [...versions]..sort((a, b) {
            final byPlatform = a.platform.compareTo(b.platform);
            if (byPlatform != 0) return byPlatform;
            return b.versionCode.compareTo(a.versionCode);
          });

        emit(state.copyWith(
          versionsStatus: RequestStatus.success,
          versions: sorted,
        ));
      },
    );
  }

  Future<void> _onCreateVersion(
    CreateVersionRequested event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;

    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      clearFormError: true,
    ));

    final result = await createVersion(
      appId: appId,
      body: _pruneNulls({
        'platform': event.platform,
        'version_name': event.versionName,
        'version_code': event.versionCode,
        'apk_url': event.apkUrl,
        'apk_size': event.apkSize,
        'changelog': event.changelog,
        'force_update_below_version_code': event.forceUpdateBelowVersionCode,
        'soft_update_below_version_code': event.softUpdateBelowVersionCode,
        'status': event.status,
      }),
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (version) async {
        emit(state.copyWith(
          formStatus: FormStatus.success,
          successMessage: 'تم تسجيل الإصدار ${version.versionName} بنجاح',
        ));
        await _loadVersionsFor(appId, emit);
      },
    );
  }

  Future<void> _onUpdateVersion(
    UpdateVersionRequested event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;

    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      clearFormError: true,
    ));

    // `changelog` و `apk_url` تقبل null صراحةً على الخادم (allow(null,'')) —
    // فإفراغ الحقل يجب أن يمسح القيمة، لا أن يُحذف المفتاح ويُبقيها كما هي.
    final result = await updateVersion(
      appId: appId,
      versionId: event.versionId,
      body: {
        'apk_url': event.apkUrl,
        'apk_size': event.apkSize,
        'changelog': event.changelog,
        'force_update_below_version_code': event.forceUpdateBelowVersionCode,
        'soft_update_below_version_code': event.softUpdateBelowVersionCode,
        'status': event.status,
      },
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (version) async {
        emit(state.copyWith(
          formStatus: FormStatus.success,
          successMessage: 'تم تعديل الإصدار ${version.versionName} بنجاح',
        ));
        await _loadVersionsFor(appId, emit);
      },
    );
  }

  Future<void> _onToggleStatus(
    ToggleVersionStatus event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;

    AppVersionRowLookup? target;
    for (final version in state.versions) {
      if (version.id == event.versionId) {
        target = AppVersionRowLookup(version.isActive, version.versionName);
        break;
      }
    }
    if (target == null) return;

    final nextStatus = target.isActive ? 'inactive' : 'active';

    emit(state.copyWith(
      busyIds: {...state.busyIds, event.versionId},
      clearActionError: true,
    ));

    final result = await updateVersion(
      appId: appId,
      versionId: event.versionId,
      body: {'status': nextStatus},
    );

    final remaining = {...state.busyIds}..remove(event.versionId);

    await result.fold(
      (failure) async => emit(state.copyWith(
        busyIds: remaining,
        actionError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(busyIds: remaining));
        await _loadVersionsFor(appId, emit);
      },
    );
  }

  Future<void> _onDeleteVersion(
    DeleteVersionRequested event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;

    emit(state.copyWith(
      busyIds: {...state.busyIds, event.versionId},
      clearActionError: true,
    ));

    final result =
        await deleteVersion(appId: appId, versionId: event.versionId);
    final remaining = {...state.busyIds}..remove(event.versionId);

    await result.fold(
      (failure) async => emit(state.copyWith(
        busyIds: remaining,
        actionError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(
          busyIds: remaining,
          successMessage: 'تم حذف الإصدار بنجاح',
        ));
        await _loadVersionsFor(appId, emit);
      },
    );
  }

  Future<void> _onUpdateApplication(
    UpdateApplicationRequested event,
    Emitter<AppVersionsState> emit,
  ) async {
    final appId = state.selectedAppId;
    if (appId == null) return;

    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      clearFormError: true,
    ));

    // الخادم يرفض المفاتيح غير المعروفة (allowUnknown: false) ويشترط min(1)،
    // كما أن `apple_store_url`/`google_play_url` يجب أن تكون URI صالحة أو ''
    // — لذا نرسل '' بدل null لمسح الرابط.
    final result = await updateApplication(
      appId: appId,
      body: {
        'update_strategy': event.updateStrategy,
        'apple_store_url': event.appleStoreUrl ?? '',
        'google_play_url': event.googlePlayUrl ?? '',
      },
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(
          formStatus: FormStatus.success,
          successMessage: 'تم تحديث إعدادات التطبيق بنجاح',
        ));
        // إعادة تحميل التطبيقات لتظهر الاستراتيجية الجديدة في البطاقة.
        add(const LoadApplications());
      },
    );
  }

  void _onClearFeedback(
    ClearFormFeedback event,
    Emitter<AppVersionsState> emit,
  ) {
    emit(state.copyWith(
      formStatus: FormStatus.idle,
      clearFormError: true,
      clearSuccessMessage: true,
      clearActionError: true,
    ));
  }

  /// الخادم يرفض المفاتيح غير المعروفة، ويعامل الغائب على أنه «لا تغيير».
  /// عند الإنشاء نحذف المفاتيح الفارغة بدل إرسال null لتُطبَّق قيم الافتراض.
  static Map<String, dynamic> _pruneNulls(Map<String, dynamic> body) {
    return {
      for (final entry in body.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }
}

/// قراءة خفيفة لحالة الصف عند التبديل — تتجنّب `firstWhere` مع `orElse`
/// الذي يتطلّب كائناً وهمياً كاملاً.
class AppVersionRowLookup {
  final bool isActive;
  final String versionName;
  const AppVersionRowLookup(this.isActive, this.versionName);
}
