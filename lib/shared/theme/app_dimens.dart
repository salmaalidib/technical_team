import 'package:flutter/widgets.dart';

/// سلّم أنصاف الأقطار (corner radius) الموحّد.
///
/// كانت الواجهات تستخدم 12 قيمة مختلفة (4,6,8,10,12,14,16,18,20,22,28,30).
/// السلّم أدناه يختصرها إلى خمس درجات دلالية.
class AppRadius {
  AppRadius._();

  /// عناصر صغيرة: شارات، رقائق، مربعات اختيار.
  static const double xs = 6;

  /// الافتراضي: بطاقات، حقول، أزرار داخل الجداول.
  static const double sm = 8;

  /// حاويات متوسطة: أقسام، لوحات جانبية.
  static const double md = 12;

  /// بطاقات وحوارات كبيرة.
  static const double lg = 16;

  /// حقول الإدخال والأزرار الرئيسية (يطابق الثيم).
  static const double xl = 18;

  /// عناصر دائرية بالكامل.
  static const double pill = 999;

  static BorderRadius get allXs => BorderRadius.circular(xs);
  static BorderRadius get allSm => BorderRadius.circular(sm);
  static BorderRadius get allMd => BorderRadius.circular(md);
  static BorderRadius get allLg => BorderRadius.circular(lg);
  static BorderRadius get allXl => BorderRadius.circular(xl);
  static BorderRadius get allPill => BorderRadius.circular(pill);
}

/// سلّم المسافات الموحّد — مضاعفات 4.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);
}
