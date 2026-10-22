import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../viewmodels/auth/session_view_model.dart';

enum AppStatusKind { maintenance, updateRequired, incomplete }

/// Full-screen blocker for maintenance / forced update / missing profile.
class AppStatusScreen extends StatelessWidget {
  const AppStatusScreen({super.key, required this.kind});

  final AppStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionViewModel>();
    final (icon, title, message) = switch (kind) {
      AppStatusKind.maintenance => (
        Icons.build_circle_rounded,
        AppStrings.maintenanceTitle,
        AppStrings.maintenanceMessage,
      ),
      AppStatusKind.updateRequired => (
        Icons.system_update_rounded,
        AppStrings.updateRequiredTitle,
        AppStrings.updateRequiredMessage,
      ),
      AppStatusKind.incomplete => (
        Icons.person_off_rounded,
        AppStrings.accountIncompleteTitle,
        AppStrings.accountIncompleteMessage,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: AppColors.primary),
              ),
              SizedBox(height: 3.h),
              Text(title, style: AppTextStyles.headline, textAlign: TextAlign.center),
              SizedBox(height: 1.h),
              Text(message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              SizedBox(height: 4.h),
              if (kind != AppStatusKind.incomplete)
                ElevatedButton.icon(
                  onPressed: session.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(AppStrings.checkAgain),
                ),
              SizedBox(height: 1.h),
              TextButton(onPressed: session.signOut, child: const Text(AppStrings.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}
