import 'package:equatable/equatable.dart';

abstract class AppVersionsEvent extends Equatable {
  const AppVersionsEvent();

  @override
  List<Object?> get props => [];
}

/// يحمّل التطبيقات الثلاثة، ثم يختار الأول تلقائياً ويحمّل إصداراته.
class LoadApplications extends AppVersionsEvent {
  const LoadApplications();
}

class SelectApplication extends AppVersionsEvent {
  final int appId;
  const SelectApplication(this.appId);

  @override
  List<Object?> get props => [appId];
}

/// إعادة تحميل إصدارات التطبيق المختار حالياً.
class ReloadVersions extends AppVersionsEvent {
  const ReloadVersions();
}

class CreateVersionRequested extends AppVersionsEvent {
  final String platform;
  final String versionName;
  final int versionCode;
  final String? apkUrl;
  final int? apkSize;
  final String? changelog;
  final int? forceUpdateBelowVersionCode;
  final int? softUpdateBelowVersionCode;
  final String status;

  const CreateVersionRequested({
    required this.platform,
    required this.versionName,
    required this.versionCode,
    this.apkUrl,
    this.apkSize,
    this.changelog,
    this.forceUpdateBelowVersionCode,
    this.softUpdateBelowVersionCode,
    required this.status,
  });

  @override
  List<Object?> get props => [
        platform,
        versionName,
        versionCode,
        apkUrl,
        apkSize,
        changelog,
        forceUpdateBelowVersionCode,
        softUpdateBelowVersionCode,
        status,
      ];
}

/// `platform` و `version_code` غير قابلين للتعديل على الخادم، لذا لا يظهران هنا.
class UpdateVersionRequested extends AppVersionsEvent {
  final int versionId;
  final String? apkUrl;
  final int? apkSize;
  final String? changelog;
  final int? forceUpdateBelowVersionCode;
  final int? softUpdateBelowVersionCode;
  final String status;

  const UpdateVersionRequested({
    required this.versionId,
    this.apkUrl,
    this.apkSize,
    this.changelog,
    this.forceUpdateBelowVersionCode,
    this.softUpdateBelowVersionCode,
    required this.status,
  });

  @override
  List<Object?> get props => [
        versionId,
        apkUrl,
        apkSize,
        changelog,
        forceUpdateBelowVersionCode,
        softUpdateBelowVersionCode,
        status,
      ];
}

/// تبديل active/inactive من زر مباشر في البطاقة — بلا فتح حوار.
class ToggleVersionStatus extends AppVersionsEvent {
  final int versionId;
  const ToggleVersionStatus(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

class DeleteVersionRequested extends AppVersionsEvent {
  final int versionId;
  const DeleteVersionRequested(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// تعديل استراتيجية التحديث وروابط المتجر للتطبيق المختار.
class UpdateApplicationRequested extends AppVersionsEvent {
  final String updateStrategy;
  final String? appleStoreUrl;
  final String? googlePlayUrl;

  const UpdateApplicationRequested({
    required this.updateStrategy,
    this.appleStoreUrl,
    this.googlePlayUrl,
  });

  @override
  List<Object?> get props => [updateStrategy, appleStoreUrl, googlePlayUrl];
}

/// يمسح رسالة النموذج بعد عرضها كـ snackbar.
class ClearFormFeedback extends AppVersionsEvent {
  const ClearFormFeedback();
}
