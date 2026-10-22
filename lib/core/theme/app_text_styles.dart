import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'app_colors.dart';

/// Central text styles. responsive_sizer's `.sp` grows quadratically with the
/// number, so the values below are tuned to land on the usual Material sizes
/// (~12/14/16/18/22/28 logical px) on a typical phone.
abstract final class AppTextStyles {
  static double get _caption => 14.5.sp;
  static double get _body => 15.6.sp;
  static double get _bodyLarge => 16.5.sp;
  static double get _title => 17.5.sp;
  static double get _headline => 19.5.sp;
  static double get _display => 22.sp;

  static TextStyle get display =>
      TextStyle(fontSize: _display, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle get headline =>
      TextStyle(fontSize: _headline, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get title => TextStyle(fontSize: _title, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get subtitle =>
      TextStyle(fontSize: _bodyLarge, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get body => TextStyle(fontSize: _body, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodySecondary =>
      TextStyle(fontSize: _body, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get caption =>
      TextStyle(fontSize: _caption, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get label =>
      TextStyle(fontSize: _caption, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get button => TextStyle(fontSize: _bodyLarge, fontWeight: FontWeight.w600, color: AppColors.white);
}
