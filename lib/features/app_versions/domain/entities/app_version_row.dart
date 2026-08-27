import 'package:equatable/equatable.dart';

/// صف من `app_versions` كما يرجعه
/// `GET /api/app-updates/admin/applications/{appId}/versions`.
class AppVersionRow extends Equatable {
  final int id;
  final int applicationId;
  final String platform;
  final String versionName;

  /// الرقم الذي يقارنه الخادم بـ `current_version_code` القادم من العميل.
  /// هو الحقل الوحيد الذي يقرّر ظهور التحديث من عدمه.
  final int versionCode;
  final String? apkUrl;
  final int? apkSize;
  final String? changelog;
  final String status; // 'active' | 'inactive'
  final int? forceUpdateBelowVersionCode;
  final int? softUpdateBelowVersionCode;

  const AppVersionRow({
    required this.id,
    required this.applicationId,
    required this.platform,
    required this.versionName,
    required this.versionCode,
    this.apkUrl,
    this.apkSize,
    this.changelog,
    required this.status,
    this.forceUpdateBelowVersionCode,
    this.softUpdateBelowVersionCode,
  });

  bool get isActive => status == 'active';

  /// أعمدة `BIGINT` (مثل `apk_size`) يعيدها درايفر `pg` **كنص** لا كرقم،
  /// تفادياً لفقدان الدقة في JS. نفس المعالجة الموجودة في `AppUpdateInfo`.
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  factory AppVersionRow.fromJson(Map<String, dynamic> json) {
    return AppVersionRow(
      id: _asInt(json['id']) ?? 0,
      applicationId: _asInt(json['application_id']) ?? 0,
      platform: _asString(json['platform']) ?? '',
      versionName: _asString(json['version_name']) ?? '',
      versionCode: _asInt(json['version_code']) ?? 0,
      apkUrl: _asString(json['apk_url']),
      apkSize: _asInt(json['apk_size']),
      changelog: _asString(json['changelog']),
      status: _asString(json['status']) ?? 'inactive',
      forceUpdateBelowVersionCode:
          _asInt(json['force_update_below_version_code']),
      softUpdateBelowVersionCode:
          _asInt(json['soft_update_below_version_code']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        applicationId,
        platform,
        versionName,
        versionCode,
        apkUrl,
        apkSize,
        changelog,
        status,
        forceUpdateBelowVersionCode,
        softUpdateBelowVersionCode,
      ];
}
