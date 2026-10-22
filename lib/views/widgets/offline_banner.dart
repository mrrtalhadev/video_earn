import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../viewmodels/connectivity_view_model.dart';

/// Thin banner shown at the top of [child] while the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: AppColors.textPrimary,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off_rounded, color: AppColors.white, size: 4.5.w),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              AppStrings.youAreOffline,
                              style: AppTextStyles.caption.copyWith(color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: !online, child: child),
        ),
      ],
    );
  }
}
