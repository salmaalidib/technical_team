import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

class AppSnackBar {

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        backgroundColor:
            isError
                ? Colors.red.shade700
                : AppColors.primary,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        duration: const Duration(seconds: 3),
      ),
    );
  }
}