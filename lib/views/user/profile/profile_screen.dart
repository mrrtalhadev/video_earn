import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_user.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);
    if (user == null) return const SizedBox.shrink();

    final tiles = [
      (Icons.history_rounded, AppStrings.history, Routes.history),
      (Icons.card_giftcard_rounded, AppStrings.referralProgram, Routes.referral),
      (Icons.receipt_long_rounded, AppStrings.myPromoteOrders, Routes.myPromoteOrders),
      (Icons.help_outline_rounded, AppStrings.faq, Routes.faq),
      (Icons.info_outline_rounded, AppStrings.aboutUs, Routes.about),
      (Icons.support_agent_rounded, AppStrings.contactUs, Routes.contact),
      (Icons.description_outlined, AppStrings.terms, Routes.terms),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(user: user),
            SizedBox(height: 2.5.h),

            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 5.h, 4.w, 3.h),
              child: Column(
                children: [
                  // ── menu card ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
                          _MenuTile(icon: tiles[i].$1, label: tiles[i].$2, onTap: () => context.push(tiles[i].$3)),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 2.5.h),

                  const LogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PROFILE HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 10.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.black, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // app bar
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.2.w),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2.8.w)),
                    child: Icon(Icons.person_rounded, color: AppColors.white, size: 5.w),
                  ),
                  SizedBox(width: 2.5.w),
                  Text(
                    AppStrings.profile,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17.sp,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(Routes.editProfile),
                    child: Container(
                      padding: EdgeInsets.all(2.2.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.8.w),
                      ),
                      child: Icon(Icons.edit_rounded, color: AppColors.white, size: 5.w),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // avatar + name
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.subscriptionActive ? AppColors.success : AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 10.w),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    user.name,
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13.sp),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    user.phone,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5.sp),
                  ),
                ],
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),

        // floating info card
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: -4.5.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -3.w,
                  top: -2.h,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Row(
                  children: [
                    _ProfileStat(
                      icon: user.subscriptionActive ? Icons.verified_rounded : Icons.lock_rounded,
                      label: 'Status',
                      value: user.subscriptionActive ? AppStrings.statusSubscribed : AppStrings.statusNotSubscribed,
                    ),
                    _VertDivider(),
                    _ProfileStat(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member Since',
                      value: Formatters.date(user.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.75), size: 4.5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16.5.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.2.h),
          Text(
            label,
            style: TextStyle(color: AppColors.white, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 5.h, color: AppColors.white.withValues(alpha: 0.12));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  MENU TILE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2.5.w),
              ),
              child: Icon(icon, color: AppColors.primary, size: 5.w),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 5.5.w),
          ],
        ),
      ),
    );
  }
}
