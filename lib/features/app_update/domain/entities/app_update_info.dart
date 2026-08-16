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

  /// أعمدة `BIGINT` (مثل `apk_size`) يُعيدها درايفر `pg` **كنص** لا كرقم،
  /// تفادياً لفقدان الدقة في JS — فتصل في JSON هكذا: `"apk_size":"31845806"`.
  /// لذا `as int?` المباشر كان يرمي `TypeError` يُبتلع في `catch` العام داخل
  /// المستودع ويتحوّل إلى «تعذّر التحقق من وجود تحديث»، أي فشل صامت كامل.
  /// نقبل هنا الرقم والنص معاً حتى لا يتعلّق عمل الميزة بنوع عمود في قاعدة
  /// البيانات قد يتغيّر لاحقاً.
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// بعض الحقول المنطقية قد تصل كـ `0/1` أو `"true"` حسب مصدرها.
  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  static String? _asString(dynamic value) => value?.toString();

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      // `id` كان `as int` بلا `?` — يرمي على أي نص أو null.
      id: _asInt(json['id']) ?? 0,
      applicationName: _asString(json['application_name']) ?? '',
      displayName: _asString(json['display_name']) ?? '',
      packageName: _asString(json['package_name']),
      versionName: _asString(json['version_name']) ?? '',
      versionCode: _asInt(json['version_code']) ?? 0,
      changelog: _asString(json['changelog']),
      forceUpdate: _asBool(json['force_update']),
      updateStrategy: _asString(json['update_strategy']) ?? 'store',
      downloadUrl: _asString(json['download_url']),
      fileSize: _asInt(json['apk_size']),
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
      forceUpdateEnabled: AppUpdateInfo._asBool(json['force_update_enabled']),
      softUpdateEnabled: AppUpdateInfo._asBool(json['soft_update_enabled']),
      // `is Map<String, dynamic>` وحده يفشل حين يأتي الـ JSON مفكوكاً كـ
      // `Map<dynamic, dynamic>`، فيُعامَل التحديث الموجود على أنه «لا تحديث».
      info: appInfo is Map
          ? AppUpdateInfo.fromJson(Map<String, dynamic>.from(appInfo))
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
