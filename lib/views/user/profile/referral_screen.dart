import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/referral_entry.dart';
import '../../../data/repositories/referral_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/referral_view_model.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ReferralViewModel(repo: ctx.read<ReferralRepository>(), uid: ctx.read<SessionViewModel>().uid!),
      child: const _ReferralView(),
    );
  }
}

class _ReferralView extends StatelessWidget {
  const _ReferralView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReferralViewModel>();
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);
    final bonus = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.referralBonus);
    if (user == null) return const SizedBox.shrink();
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: vm.load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── header ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 3.h),
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
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: EdgeInsets.all(2.2.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2.8.w),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 4.5.w),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          AppStrings.referralProgram,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // referral code
                    Text(
                      AppStrings.yourReferralCode,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    SelectableText(
                      user.referralCode,
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28.sp,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // copy + share buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: user.referralCode));
                              if (context.mounted) AppSnackbars.info(context, AppStrings.copied);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3.w),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_rounded, color: AppColors.white, size: 4.5.w),
                                  SizedBox(width: 2.w),
                                  Text(
                                    AppStrings.copy,
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => SharePlus.instance.share(
                              ShareParams(text: AppStrings.referralShareMessage(user.referralCode, AppStrings.appName)),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(3.w),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share_rounded, color: AppColors.primary, size: 4.5.w),
                                  SizedBox(width: 2.w),
                                  Text(
                                    AppStrings.share,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── body ──
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 3.h),
                child: Column(
                  children: [
                    // stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: AppStrings.totalReferred,
                            value: Formatters.number(vm.totalReferred),
                            icon: Icons.group_add_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _StatCard(
                            title: AppStrings.subscribedReferrals,
                            value: Formatters.number(user.referralCount),
                            icon: Icons.verified_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.w),
                    _StatCard(
                      title: AppStrings.referralEarnings,
                      value: Formatters.pkr(user.totalReferralEarned),
                      icon: Icons.card_giftcard_rounded,
                      color: AppColors.info,
                    ),

                    SizedBox(height: 2.h),

                    NoticeBanner.info(
                      AppStrings.referralExplainer(Formatters.pkr(bonus)),
                      title: AppStrings.referralExplainerTitle,
                    ),

                    const SectionHeader(title: AppStrings.totalReferred),

                    if (!vm.loaded && !vm.hasError)
                      const SkeletonList(count: 3)
                    else if (vm.hasError && vm.entries.isEmpty)
                      ErrorState(message: vm.errorMessage, onRetry: vm.load, compact: true)
                    else if (vm.entries.isEmpty)
                      const EmptyState(
                        title: AppStrings.noReferrals,
                        message: AppStrings.noReferralsMessage,
                        icon: Icons.group_add_rounded,
                        compact: true,
                      )
                    else
                      ...vm.entries.map((e) => _ReferralTile(entry: e)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  STAT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2.5.w)),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w900, fontSize: 17.sp),
                ),
                SizedBox(height: 0.2.h),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  REFERRAL TILE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.entry});
  final ReferralEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  entry.refereeName.isEmpty ? '?' : entry.refereeName[0].toUpperCase(),
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.refereeName, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
                  SizedBox(height: 0.2.h),
                  Text(
                    Formatters.date(entry.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            entry.bonusPaid
                ? StatusChip.positive(AppStrings.referralBonusEarned(Formatters.pkr(entry.bonus)))
                : StatusChip.warning(AppStrings.referralPending),
          ],
        ),
      ),
    );
  }
}
