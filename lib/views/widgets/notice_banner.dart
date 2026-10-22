import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Coloured notice box (e.g. "account blocked").
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    required this.color,
    required this.background,
    this.icon = Icons.info_rounded,
    this.title,
  });

  factory NoticeBanner.error(String message, {String? title}) => NoticeBanner(
    message: message,
    title: title,
    color: AppColors.error,
    background: AppColors.errorLight,
    icon: Icons.error_rounded,
  );

  factory NoticeBanner.warning(String message, {String? title}) => NoticeBanner(
    message: message,
    title: title,
    color: AppColors.warning,
    background: AppColors.warningLight,
    icon: Icons.hourglass_top_rounded,
  );

  factory NoticeBanner.info(String message, {String? title}) =>
      NoticeBanner(message: message, title: title, color: AppColors.info, background: AppColors.infoLight);

  factory NoticeBanner.success(String message, {String? title}) => NoticeBanner(
    message: message,
    title: title,
    color: AppColors.success,
    background: AppColors.successLight,
    icon: Icons.check_circle_rounded,
  );

  final String message;
  final String? title;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5.w),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(3.w)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 5.5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: AppTextStyles.label.copyWith(color: color)),
                  SizedBox(height: 0.3.h),
                ],
                Text(message, style: AppTextStyles.body.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
