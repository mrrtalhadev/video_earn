import 'package:flutter/material.dart';

/// YouTube-style red & white palette.
abstract final class AppColors {
  static const Color primary = Color(0xFFFF0000);
  static const Color primaryDark = Color(0xFFCC0000);
  static const Color primaryLight = Color(0xFFFFE5E5);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color textPrimary = Color(0xFF0F0F0F);
  static const Color textSecondary = Color(0xFF606060);
  static const Color divider = Color(0xFFE5E5E5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color shadow = Color(0x14000000);
  static const Color scrim = Color(0x8A000000);

  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFEF6C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF7F7F7);
}
