import 'package:flutter/material.dart';

import 'app_colors.dart';

/// سلّم الخطوط الموحّد.
///
/// المرجع الأول هو `Theme.of(context).textTheme`؛ هذه الفئة اختصار ثابت
/// (const) للحالات التي لا يتوفر فيها `context` أو داخل قوائم ثابتة.
/// لا تكتب `TextStyle(fontSize: ..)` يدوياً في الواجهات.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Cairo';

  // العناوين
  static const TextStyle displayLarge = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // المتون
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// المقاس الأكثر استخداماً في الجداول والنماذج.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// نص مساعد صغير: تلميحات، تسميات الشارات.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // التسميات
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ------------------------------------------------- توافق مع الاستخدام السابق
  /// @Deprecated — استخدم [headline].
  static const TextStyle heading = headline;

  /// @Deprecated — استخدم [bodySmall] أو [labelMedium].
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
