import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_bar_x.dart';
import '../widgets/logout_button.dart';
import '../widgets/notice_banner.dart';
import '../widgets/section_header.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (Icons.video_library_rounded, AppStrings.taskManagement, Routes.adminTasks),
      (Icons.campaign_rounded, AppStrings.promoteOrdersManagement, Routes.adminPromoteOrders),
      (Icons.sell_rounded, AppStrings.promotePlansManagement, Routes.adminPromotePlans),
      (Icons.settings_rounded, AppStrings.appSettings, Routes.adminSettings),
    ];
    return Scaffold(
      appBar: const AppBarX(title: AppStrings.navMore, automaticallyImplyLeading: false),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(tiles[i].$1, color: AppColors.primary),
                    title: Text(tiles[i].$2, style: AppTextStyles.body),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(tiles[i].$3),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          NoticeBanner.warning(AppStrings.adminSecurityNote),
          const LogoutButton(),
        ],
      ),
    );
  }
}
