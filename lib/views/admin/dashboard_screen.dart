import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/stats_repository.dart';
import '../../viewmodels/admin/dashboard_view_model.dart';
import '../widgets/app_bar_x.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/state_views.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DashboardViewModel(ctx.read<StatsRepository>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final s = vm.stats;

    Widget body;
    if (s == null && vm.hasError) {
      body = ErrorState(message: vm.errorMessage, onRetry: vm.refresh);
    } else if (s == null) {
      body = GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(4.w),
        mainAxisSpacing: 3.w,
        crossAxisSpacing: 3.w,
        childAspectRatio: 1.1,
        children: List.generate(8, (_) => SkeletonBox(height: 15.h)),
      );
    } else {
      final cards = [
        (AppStrings.totalUsers, Formatters.number(s.totalUsers), Icons.people_alt_rounded, AppColors.info),
        (AppStrings.activeUsers, Formatters.number(s.activeUsers), Icons.verified_user_rounded, AppColors.success),
        (AppStrings.depositedToday, Formatters.pkr(s.depositedToday), Icons.today_rounded, AppColors.primary),
        (AppStrings.depositedLifetime, Formatters.pkr(s.depositedLifetime), Icons.savings_rounded, AppColors.primary),
        (AppStrings.withdrawnToday, Formatters.pkr(s.withdrawnToday), Icons.north_east_rounded, AppColors.textPrimary),
        (
          AppStrings.withdrawnLifetime,
          Formatters.pkr(s.withdrawnLifetime),
          Icons.payments_rounded,
          AppColors.textPrimary,
        ),
        (AppStrings.promoteDeposits, Formatters.pkr(s.promoteDeposits), Icons.campaign_rounded, AppColors.warning),
        (
          AppStrings.pendingWithdrawAmount,
          Formatters.pkr(s.pendingWithdrawAmount),
          Icons.hourglass_top_rounded,
          AppColors.warning,
        ),
      ];
      body = RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            _PendingRow(
              icon: Icons.verified_rounded,
              label: AppStrings.pendingSubscriptions,
              count: s.pendingSubscriptions,
              onTap: () => context.go(Routes.adminSubscriptions),
            ),
            _PendingRow(
              icon: Icons.account_balance_wallet_rounded,
              label: AppStrings.pendingWithdrawals,
              count: s.pendingWithdrawals,
              onTap: () => context.go(Routes.adminWithdrawals),
            ),
            _PendingRow(
              icon: Icons.campaign_rounded,
              label: AppStrings.pendingPromotions,
              count: s.pendingPromotions,
              onTap: () => context.push(Routes.adminPromoteOrders),
            ),
            SizedBox(height: 1.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 3.w,
              crossAxisSpacing: 3.w,
              childAspectRatio: 1.1,
              children: [
                for (final (title, value, icon, color) in cards)
                  StatCard(title: title, value: value, icon: icon, color: color),
              ],
            ),
            SizedBox(height: 1.5.h),
            Text(
              '${AppStrings.lastUpdated(Formatters.dateTime(s.fetchedAt))} · ${AppStrings.pullToRefresh}',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBarX(
        title: AppStrings.adminPanel,
        showLogo: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: AppStrings.retry,
            onPressed: vm.isLoading ? null : vm.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.icon, required this.label, required this.count, required this.onTap});

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 6.w),
            SizedBox(width: 3.w),
            Expanded(child: Text(label, style: AppTextStyles.subtitle)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(5.w),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.label.copyWith(color: count > 0 ? AppColors.white : AppColors.textSecondary),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 6.w),
          ],
        ),
      ),
    );
  }
}
