import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/app_version_row.dart';
import '../../domain/entities/managed_application.dart';

class AppVersionsState extends Equatable {
  /// تحميل التطبيقات الثلاثة.
  final RequestStatus appsStatus;
  final List<ManagedApplication> applications;
  final String? appsError;

  /// التطبيق المختار حالياً في التبويبات.
  final int? selectedAppId;

  /// تحميل إصدارات التطبيق المختار.
  final RequestStatus versionsStatus;
  final List<AppVersionRow> versions;
  final String? versionsError;

  /// إرسال نموذج (إنشاء/تعديل إصدار أو تعديل التطبيق).
  final FormStatus formStatus;
  final String? formError;

  /// رسالة نجاح لمرة واحدة تُعرض كـ snackbar ثم تُمسح.
  final String? successMessage;

  /// معرّفات الإصدارات التي يجري تبديل حالتها أو حذفها الآن.
  final Set<int> busyIds;

  /// خطأ إجراء مباشر (تبديل/حذف) — snackbar لا يوقف الشاشة.
  final String? actionError;

  const AppVersionsState({
    this.appsStatus = RequestStatus.initial,
    this.applications = const [],
    this.appsError,
    this.selectedAppId,
    this.versionsStatus = RequestStatus.initial,
    this.versions = const [],
    this.versionsError,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.successMessage,
    this.busyIds = const {},
    this.actionError,
  });

  ManagedApplication? get selectedApplication {
    final id = selectedAppId;
    if (id == null) return null;
    for (final app in applications) {
      if (app.id == id) return app;
    }
    return null;
  }

  /// أعلى `version_code` مسجَّل على المنصة — أساس الرقم المقترح تلقائياً
  /// والتحذير من رقم أصغر أو مساوٍ (وهو ما يكسر الميزة بصمت).
  int highestVersionCodeFor(String platform) {
    var highest = 0;
    for (final version in versions) {
      if (version.platform == platform && version.versionCode > highest) {
        highest = version.versionCode;
      }
    }
    return highest;
  }

  /// أرقام الإصدارات المستخدَمة على المنصة — للتحقق الفوري قبل الإرسال،
  /// بدل انتظار 409 من الخادم.
  Set<int> usedVersionCodesFor(String platform) => versions
      .where((version) => version.platform == platform)
      .map((version) => version.versionCode)
      .toSet();

  AppVersionsState copyWith({
    RequestStatus? appsStatus,
    List<ManagedApplication>? applications,
    String? appsError,
    bool clearAppsError = false,
    int? selectedAppId,
    RequestStatus? versionsStatus,
    List<AppVersionRow>? versions,
    String? versionsError,
    bool clearVersionsError = false,
    FormStatus? formStatus,
    String? formError,
    bool clearFormError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    Set<int>? busyIds,
    String? actionError,
    bool clearActionError = false,
  }) {
    return AppVersionsState(
      appsStatus: appsStatus ?? this.appsStatus,
      applications: applications ?? this.applications,
      appsError: clearAppsError ? null : (appsError ?? this.appsError),
      selectedAppId: selectedAppId ?? this.selectedAppId,
      versionsStatus: versionsStatus ?? this.versionsStatus,
      versions: versions ?? this.versions,
      versionsError:
          clearVersionsError ? null : (versionsError ?? this.versionsError),
      formStatus: formStatus ?? this.formStatus,
      formError: clearFormError ? null : (formError ?? this.formError),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      busyIds: busyIds ?? this.busyIds,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        appsStatus,
        applications,
        appsError,
        selectedAppId,
        versionsStatus,
        versions,
        versionsError,
        formStatus,
        formError,
        successMessage,
        busyIds,
        actionError,
      ];
}
