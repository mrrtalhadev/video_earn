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
import '../../../data/repositories/wallet_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/wallet_view_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/transaction_tile.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => WalletViewModel(repo: ctx.read<WalletRepository>(), uid: ctx.read<SessionViewModel>().uid!),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);
    final vm = context.watch<WalletViewModel>();
    if (user == null) return const SizedBox.shrink();

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
              _WalletHeader(user: user),
              SizedBox(height: 2.5.h),

              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 5.h, 4.w, 3.h),
                child: Column(
                  children: [
                    // ── stat grid ──
                    _StatGrid(user: user),

                    SizedBox(height: 2.5.h),

                    // ── action buttons ──
                    _ActionButtons(user: user),

                    SizedBox(height: 0.5.h),

                    // ── recent activity ──
                    SectionHeader(
                      title: AppStrings.recentActivity,
                      actionLabel: AppStrings.viewAll,
                      onAction: () => context.push(Routes.history),
                    ),

                    _RecentActivity(vm: vm),
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
//  WALLET HEADER — dark gradient + floating balance card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 10.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.black, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // app bar
                  Row(
                    children: [
                      // SizedBox(width: 3.w),
                      Text(
                        AppStrings.wallet,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.sp,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(Routes.history),
                        child: Container(
                          padding: EdgeInsets.all(2.2.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2.8.w),
                          ),
                          child: Icon(Icons.history_rounded, color: AppColors.white, size: 5.w),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // balance display
                  Column(
                    children: [
                      Text(
                        AppStrings.availableBalance,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.pkr(user.balance),
                          style: AppTextStyles.display.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 32.sp,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ],
          ),
        ),

        // floating quick stats card
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: -4.5.h,
          child: _QuickStats(user: user),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  QUICK STATS — floating row: earned, withdrawn, pending
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _QuickStatItem(icon: Icons.trending_up_rounded, label: 'Earned', value: Formatters.pkr(user.totalEarned)),
              _VertDivider(),
              _QuickStatItem(
                icon: Icons.payments_rounded,
                label: 'Withdrawn',
                value: Formatters.pkr(user.totalWithdrawn),
              ),
              _VertDivider(),
              _QuickStatItem(
                icon: Icons.hourglass_top_rounded,
                label: 'Pending',
                value: Formatters.pkr(user.pendingWithdraw),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({required this.icon, required this.label, required this.value});
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
//  STAT GRID — referral earnings + completed tasks
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModernStatCard(
            title: AppStrings.referralEarnings,
            value: Formatters.pkr(user.totalReferralEarned),
            icon: Icons.card_giftcard_rounded,
            color: AppColors.info,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _ModernStatCard(
            title: AppStrings.completedTasks,
            value: Formatters.number(user.completedTasksCount),
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  const _ModernStatCard({required this.title, required this.value, required this.icon, required this.color});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2.5.w)),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(height: 1.5.h),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w900, fontSize: 17.sp),
          ),
          SizedBox(height: 0.3.h),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ACTION BUTTONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientButton(
            label: AppStrings.withdraw,
            icon: Icons.north_east_rounded,
            onTap: () => context.push(Routes.withdraw),
          ),
        ),
        if (!user.subscriptionActive) ...[
          SizedBox(width: 3.w),
          Expanded(
            child: _OutlineButton(
              label: AppStrings.deposit,
              icon: Icons.south_west_rounded,
              onTap: () => context.push(Routes.subscribe),
            ),
          ),
        ],
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14.5.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14.5.sp),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  RECENT ACTIVITY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.vm});
  final WalletViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.loaded && !vm.hasError) {
      return const SkeletonList(count: 3);
    }

    if (vm.hasError && vm.recent.isEmpty) {
      return ErrorState(message: vm.errorMessage, onRetry: vm.load, compact: true);
    }

    if (vm.recent.isEmpty) {
      return const EmptyState(
        title: AppStrings.noTransactions,
        message: AppStrings.noTransactionsMessage,
        icon: Icons.receipt_long_rounded,
        compact: true,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          for (var i = 0; i < vm.recent.length; i++) ...[
            if (i > 0) Divider(color: Colors.grey.shade100, height: 1),
            TransactionTile(tx: vm.recent[i]),
          ],
        ],
      ),
    );
  }
}
