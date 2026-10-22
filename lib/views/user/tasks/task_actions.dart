import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/video_task.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/tasks_view_model.dart';
import '../../widgets/primary_button.dart';

/// Shared tap behaviour for task cards (Home and See All).
void openTask(BuildContext context, VideoTask task) {
  final session = context.read<SessionViewModel>();
  final user = session.user;
  if (user == null || !user.canEarn) {
    _showLockedSheet(context, pending: user?.hasPendingSubscription ?? false);
    return;
  }
  if (context.read<TasksViewModel>().isCompleted(task.id)) {
    AppSnackbars.info(context, AppStrings.alreadyCompleted);
    return;
  }
  if (task.ownerUid == user.uid) {
    AppSnackbars.info(context, AppStrings.ownVideoNotice);
    return;
  }
  context.push(Routes.player, extra: task);
}

void _showLockedSheet(BuildContext context, {required bool pending}) {
  final price = context.read<SessionViewModel>().settingsOrDefault.subscriptionPrice;
  showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(
                pending ? Icons.hourglass_top_rounded : Icons.lock_rounded,
                color: AppColors.primary,
                size: 10.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(pending ? AppStrings.paymentUnderReviewTitle : AppStrings.lockedTaskTitle, style: AppTextStyles.title),
            SizedBox(height: 1.h),
            Text(
              pending ? AppStrings.paymentUnderReviewMessage : AppStrings.lockedTaskMessage(Formatters.pkr(price)),
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            PrimaryButton(
              label: pending ? AppStrings.ok : AppStrings.subscribeNow,
              onPressed: () {
                Navigator.pop(sheet);
                if (!pending) context.push(Routes.subscribe);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
