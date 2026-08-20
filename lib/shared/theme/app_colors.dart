import 'package:flutter/material.dart';

/// المصدر الوحيد لألوان التطبيق.
///
/// لا تكتب `Color(0x...)` أو `Colors.white` داخل الواجهات — أضف الرمز هنا
/// واستخدمه من `AppColors`. أي لون جديد يجب أن يكون له اسم دلالي (semantic).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- الهوية
  /// اللون الأساسي للعلامة (أخضر داكن).
  static const Color primary = Color(0xff25624F);

  /// درجة أغمق من الأساسي — تُستخدم في خلفيات المصادقة والتدرجات.
  static const Color primaryDark = Color(0xFF163E31);

  /// خلفية فاتحة مشتقة من الأساسي (حالات محددة/نشطة).
  static const Color lightPrimary = Color(0xffEAF3F0);

  /// اللون الثانوي (ذهبي).
  static const Color secondary = Color(0xffB8A47C);

  /// درجة الذهبي المستخدمة في شاشات المصادقة.
  static const Color secondaryAlt = Color(0xFFB9A779);

  /// خلفية فاتحة مشتقة من الثانوي.
  static const Color lightSecondary = Color(0xFFEDEBE0);

  // --------------------------------------------------------------- الأسطح
  /// خلفية التطبيق العامة.
  static const Color background = Color(0xffF5F7FA);

  /// سطح البطاقات والحوارات.
  static const Color surface = Colors.white;

  /// سطح بديل: رؤوس الجداول وأشرطة الصفحات (كان `0xffF0EFE7` مكرراً).
  static const Color surfaceAlt = Color(0xffF0EFE7);

  /// سطح خافت لأقسام التفاصيل داخل الحوارات.
  static const Color surfaceMuted = Color(0xffFAF9F5);

  /// خلفية حقول الإدخال.
  static const Color inputBackground = Color(0xffECE8DC);

  /// خلفية حقل إدخال محايدة (شاشات المصادقة).
  static const Color inputBackgroundAlt = Color(0xFFFAFAFA);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ---------------------------------------------------------------- النصوص
  static const Color textPrimary = Color(0xff1E1E1E);
  static const Color textSecondary = Color(0xff817D7D);

  /// نص داكن محايد (شاشات المصادقة).
  static const Color textCharcoal = Color(0xFF3D3A3B);

  /// نص/أيقونة خافتة — عناصر معطّلة أو تلميحات.
  static const Color textMuted = Color(0xFF757575);

  /// نص على خلفية داكنة.
  static const Color textOnPrimary = Colors.white;

  // ---------------------------------------------------------------- الحدود
  static const Color border = Color(0xffE5E7EB);

  /// حد أفتح للفواصل الداخلية.
  static const Color borderLight = Color(0xFFEEEEEE);

  /// حد أغمق قليلاً للحقول غير المفعّلة.
  static const Color borderStrong = Color(0xFFBDBDBD);

  // -------------------------------------------------------------- الحالات
  /// خطأ / رفض.
  static const Color error = Color(0xffEB2222);

  /// خطأ بدرجة أهدأ (شارات الحالة).
  static const Color errorDark = Color(0xffC62828);

  /// خلفية فاتحة لحالة الخطأ.
  static const Color errorLight = Color(0xffFDECEC);

  /// نجاح / اعتماد.
  static const Color success = Color(0xff2E7D32);

  /// تحذير / قيد الانتظار.
  static const Color warning = Color(0xffB26A00);

  /// تحذير بدرجة ذهبية (تنبيهات النماذج).
  static const Color warningAlt = Color(0xffB7791F);

  /// حالة محايدة / غير نشطة.
  static const Color neutral = Color(0xff757575);

  /// لون تمييز في الشريط العلوي.
  static const Color accentMaroon = Color(0xff7A2334);

  // ------------------------------------------- تدرجات شفافة (تصلح داخل const)
  /// نص ثانوي على خلفية داكنة — ذهبي فاتح بشفافية 85%.
  static const Color lightSecondaryTranslucent = Color(0xD9EDEBE0);

  /// نص خافت على خلفية داكنة — أبيض بشفافية 90%.
  static const Color whiteTranslucent = Color(0xE6FFFFFF);

  // ------------------------------------------------------ الظلال والحُجُب
  /// حجاب خلف الحوارات (barrier).
  static const Color scrim = Color(0x8C000000);

  /// ظل خفيف للبطاقات.
  static const Color shadowSoft = Color(0x0F000000);

  /// ظل أخف للبطاقات الثانوية.
  static const Color shadowFaint = Color(0x08000000);

  /// ظل أوضح للعناصر العائمة (قوائم منسدلة، إشعارات).
  static const Color shadowMedium = Color(0x1F000000);

  /// حجاب أخف للوحات الجانبية.
  static const Color scrimLight = Color(0x52000000);

  /// نص ثانوي محايد (كان Colors.black54).
  static const Color textTertiary = Color(0x8A000000);

  /// أيقونة خافتة للحالات الفارغة (كان Colors.black26).
  static const Color iconMuted = Color(0x42000000);

  // -------------------------------------------------- هياكل التحميل (skeleton)
  /// لون أساس عنصر التحميل النابض.
  static const Color skeletonBase = Color(0xffE7E9EC);

  /// لون الوميض المار فوق عنصر التحميل.
  static const Color skeletonHighlight = Color(0xffF6F7F9);
}
