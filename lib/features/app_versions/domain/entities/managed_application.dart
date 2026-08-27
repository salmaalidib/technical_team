import 'package:equatable/equatable.dart';

/// صف من جدول `applications` كما يرجعه `GET /api/app-updates/admin/applications`.
///
/// هذه الكيانات الثلاثة (citizen / employee / technical_team) مزروعة في قاعدة
/// البيانات ولا تُنشأ ولا تُحذف من الواجهة — يُعدَّل منها فقط `update_strategy`
/// وروابط المتجر. لذلك لا يوجد هنا create/delete، على خلاف بقية الفيتشرات.
class ManagedApplication extends Equatable {
  final int id;

  /// المُعرِّف الذي يرسله التطبيق العميل في `?app=` — غير قابل للتعديل.
  final String name;
  final String displayName;
  final String? packageName;
  final String? appleStoreUrl;
  final String? googlePlayUrl;

  /// 'store' = فتح رابط المتجر خارجياً · 'direct' = تنزيل الملف وتثبيته.
  final String updateStrategy;

  const ManagedApplication({
    required this.id,
    required this.name,
    required this.displayName,
    this.packageName,
    this.appleStoreUrl,
    this.googlePlayUrl,
    required this.updateStrategy,
  });

  bool get isDirect => updateStrategy == 'direct';

  /// المنصّات المنطقية لكل تطبيق. تطبيق التقني سطح مكتب ويندوز فقط، أما
  /// المواطن والموظف فتطبيقا هاتف — عرض المنصات الثلاث لكلٍّ منها كان
  /// سيسمح بتسجيل إصدار windows لتطبيق المواطن (صف لا يقرأه أحد أبداً).
  List<String> get platforms =>
      name == 'technical_team' ? const ['windows'] : const ['android', 'ios'];

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  factory ManagedApplication.fromJson(Map<String, dynamic> json) {
    return ManagedApplication(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']) ?? '',
      displayName: _asString(json['display_name']) ?? '',
      packageName: _asString(json['package_name']),
      appleStoreUrl: _asString(json['apple_store_url']),
      googlePlayUrl: _asString(json['google_play_url']),
      updateStrategy: _asString(json['update_strategy']) ?? 'store',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        packageName,
        appleStoreUrl,
        googlePlayUrl,
        updateStrategy,
      ];
}
