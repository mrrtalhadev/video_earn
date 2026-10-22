import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_task.dart';

/// YouTube-style task card: thumbnail with duration badge, lock overlay when
/// not subscribed, "Completed" badge when done, title and reward.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.reward,
    required this.locked,
    required this.completed,
    required this.onTap,
  });

  final VideoTask task;
  final int reward;
  final bool locked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3.w),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: task.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.shimmerBase),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: Icon(Icons.ondemand_video_rounded, size: 12.w, color: AppColors.divider),
                    ),
                  ),
                  if (locked)
                    Container(
                      color: AppColors.scrim,
                      child: Icon(Icons.lock_rounded, color: AppColors.white, size: 12.w),
                    )
                  else if (!completed)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: Icon(Icons.play_arrow_rounded, color: AppColors.white, size: 9.w),
                      ),
                    ),
                  Positioned(
                    right: 2.w,
                    bottom: 1.h,
                    child: _Badge(
                      text: Formatters.duration(task.durationSeconds),
                      color: AppColors.black.withValues(alpha: 0.8),
                    ),
                  ),
                  if (completed)
                    Positioned(
                      left: 2.w,
                      top: 1.h,
                      child: _Badge(
                        text: AppStrings.statusCompleted,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(task.title, style: AppTextStyles.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: completed ? AppColors.successLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(5.w),
                ),
                child: Text(
                  AppStrings.rewardLabel(Formatters.pkr(reward)),
                  style: AppTextStyles.label.copyWith(color: completed ? AppColors.success : AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.8.w, vertical: 0.3.h),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5.w)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: AppColors.white, size: 3.5.w), SizedBox(width: 1.w)],
          Text(text, style: AppTextStyles.label.copyWith(color: AppColors.white)),
        ],
      ),
    );
  }
}
