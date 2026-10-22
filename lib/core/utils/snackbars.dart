import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme/app_colors.dart';

abstract final class AppSnackbars {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error, Icons.error_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.textPrimary, Icons.info_rounded);

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: AppColors.white),
              SizedBox(width: 3.w),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
