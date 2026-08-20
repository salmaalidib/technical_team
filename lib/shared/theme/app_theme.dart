import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

/// ثيم التطبيق الموحّد.
///
/// كل ما يمكن توريثه يُعرّف هنا مرة واحدة، حتى لا تعيد الواجهات تعريف
/// الألوان والخطوط والحواف يدوياً.
class AppTheme {
  AppTheme._();

  static const TextTheme _cairoTextTheme = TextTheme(
    headlineLarge: AppTextStyles.displayLarge,
    headlineMedium: AppTextStyles.headline,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.caption,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    textTheme: _cairoTextTheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleTextStyle: AppTextStyles.titleMedium,
      contentTextStyle: AppTextStyles.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightPrimary,
      labelStyle: AppTextStyles.caption,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.allXs),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTextStyles.labelMedium,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg + 2,
        vertical: AppSpacing.lg + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.allXl,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.allXl,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.allXl,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.allXl,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.allXl,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textMuted,
        textStyle: AppTextStyles.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        minimumSize: const Size(double.infinity, 58),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        minimumSize: const Size(0, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    ),
  );
}
