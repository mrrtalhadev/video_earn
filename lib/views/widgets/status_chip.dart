import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/order_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, required this.background, this.icon});

  /// pending → orange, approved → green, rejected → red.
  factory StatusChip.order(OrderStatus status) => switch (status) {
    OrderStatus.pending => const StatusChip(
      label: AppStrings.statusPending,
      color: AppColors.warning,
      background: AppColors.warningLight,
      icon: Icons.schedule_rounded,
    ),
    OrderStatus.approved => const StatusChip(
      label: AppStrings.statusApproved,
      color: AppColors.success,
      background: AppColors.successLight,
      icon: Icons.check_circle_rounded,
    ),
    OrderStatus.rejected => const StatusChip(
      label: AppStrings.statusRejected,
      color: AppColors.error,
      background: AppColors.errorLight,
      icon: Icons.cancel_rounded,
    ),
  };

  factory StatusChip.positive(String label) =>
      StatusChip(label: label, color: AppColors.success, background: AppColors.successLight);

  factory StatusChip.negative(String label) =>
      StatusChip(label: label, color: AppColors.error, background: AppColors.errorLight);

  factory StatusChip.warning(String label) =>
      StatusChip(label: label, color: AppColors.warning, background: AppColors.warningLight);

  factory StatusChip.neutral(String label) =>
      StatusChip(label: label, color: AppColors.textSecondary, background: AppColors.surface);

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(5.w)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 3.5.w, color: color), SizedBox(width: 1.w)],
          Text(label, style: AppTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }
}
