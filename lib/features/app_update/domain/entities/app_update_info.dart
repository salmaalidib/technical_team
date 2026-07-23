import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';

/// معلومات الإصدار الأحدث المتاح، كما يرجعها `GET /api/app-updates/settings`
/// داخل `data.app_info` (أو `null` إن كان التطبيق محدَّثاً).
class AppUpdateInfo extends Equatable {
  final int id;
  final String applicationName;
  final String displayName;
  final String? packageName;
  final String versionName;
  final int versionCode;
  final String? changelog;
  final bool forceUpdate;
  final String updateStrategy; // 'direct' | 'store'
  final String? downloadUrl;
  final int? fileSize;

  const AppUpdateInfo({
    required this.id,
    required this.applicationName,
    required this.displayName,
    this.packageName,
    required this.versionName,
    required this.versionCode,
    this.changelog,
    required this.forceUpdate,
    required this.updateStrategy,
    this.downloadUrl,
    this.fileSize,
  });

  /// هذا التطبيق سطح مكتب Windows فقط — direct تعني تنزيل .exe وتثبيته صامتاً.
  /// (لا Android/iOS هنا؛ قارن مع منطق [التوثيق الأصلي] الذي يدعم منصات متعددة).
  bool get isDirectInstall {
    final url = downloadUrl?.trim();
    return updateStrategy == 'direct' &&
        Platform.isWindows &&
        url != null &&
        url.isNotEmpty;
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      id: json['id'] as int,
      applicationName: json['application_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      packageName: json['package_name'] as String?,
      versionName: json['version_name'] as String? ?? '',
      versionCode: json['version_code'] as int? ?? 0,
      changelog: json['changelog'] as String?,
      forceUpdate: json['force_update'] as bool? ?? false,
      updateStrategy: json['update_strategy'] as String? ?? 'store',
      downloadUrl: json['download_url'] as String?,
      fileSize: json['apk_size'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        applicationName,
        displayName,
        packageName,
        versionName,
        versionCode,
        changelog,
        forceUpdate,
        updateStrategy,
        downloadUrl,
        fileSize,
      ];
}

/// غلاف استجابة نقطة النهاية كاملة: `force_update_enabled` / `soft_update_enabled`
/// يحكمان عرض الشاشة الإجبارية أو الحوار الاختياري؛ `info == null` = محدَّث.
class UpdateCheckResult extends Equatable {
  final bool forceUpdateEnabled;
  final bool softUpdateEnabled;
  final AppUpdateInfo? info;

  const UpdateCheckResult({
    required this.forceUpdateEnabled,
    required this.softUpdateEnabled,
    this.info,
  });

  bool get hasUpdate => info != null;

  factory UpdateCheckResult.fromJson(Map<String, dynamic> json) {
    final appInfo = json['app_info'];
    return UpdateCheckResult(
      forceUpdateEnabled: json['force_update_enabled'] as bool? ?? false,
      softUpdateEnabled: json['soft_update_enabled'] as bool? ?? false,
      info: appInfo is Map<String, dynamic>
          ? AppUpdateInfo.fromJson(appInfo)
          : null,
    );
  }

  static const noUpdate = UpdateCheckResult(
    forceUpdateEnabled: false,
    softUpdateEnabled: false,
  );

  @override
  List<Object?> get props => [forceUpdateEnabled, softUpdateEnabled, info];
}
