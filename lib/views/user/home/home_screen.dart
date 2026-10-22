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
import '../../../viewmodels/user/tasks_view_model.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_card.dart';
import '../tasks/task_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TasksViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);
    final tasksVm = context.watch<TasksViewModel>();
    if (user == null) return const SizedBox.shrink();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: tasksVm.load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeroHeader(user: user),
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
                child: Column(
                  children: [
                    _SubscriptionBanner(user: user),
                    SizedBox(height: 0.5.h),
                    SectionHeader(
                      title: AppStrings.availableTasks,
                      actionLabel: AppStrings.seeAll,
                      onAction: tasksVm.tasks.isEmpty ? null : () => context.push(Routes.tasks),
                    ),
                    _TaskPreview(user: user),
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
//  HERO HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final reward = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.videoReward);
    final taskCount = context.select<TasksViewModel, int>((vm) => vm.tasks.length);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── main gradient container ──
        Container(
          padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 15.h),
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
              // ── content ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // app bar
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.2.w),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2.8.w)),
                        child: Icon(Icons.play_arrow_rounded, color: AppColors.white, size: 5.w),
                      ),
                      SizedBox(width: 2.5.w),
                      Text(
                        AppStrings.appName,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // greeting + avatar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.greeting(user.firstName),
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22.sp,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              user.subscriptionActive ? 'Welcome back!' : 'Activate to start earning',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(0.8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: user.subscriptionActive ? AppColors.success : AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 5.5.w,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16.sp),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),
                ],
              ),
            ],
          ),
        ),

        // ── floating gradient balance card ──
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: -5.5.h,
          child: _BalanceCard(user: user, reward: reward, taskCount: taskCount),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BALANCE CARD — gradient, floating, with stats row inside
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.user, required this.reward, required this.taskCount});

  final AppUser user;
  final int reward;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // subtle inner decorative circle
          Positioned(
            right: -5.w,
            top: -3.h,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.06)),
            ),
          ),
          Positioned(
            left: -4.w,
            bottom: -2.h,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.04)),
            ),
          ),

          // card content
          Padding(
            padding: EdgeInsets.all(4.5.w),
            child: Column(
              children: [
                // top: wallet icon + balance + status
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.8.w),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.white, size: 6.w),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.availableBalance,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Formatters.pkr(user.balance),
                              style: AppTextStyles.display.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26.sp,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2.5.w),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        user.subscriptionActive ? AppStrings.statusActive : AppStrings.statusLocked,
                        style: TextStyle(color: AppColors.white, fontSize: 12.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // divider
                Container(height: 1, color: AppColors.white.withValues(alpha: 0.12)),

                SizedBox(height: 1.5.h),

                // bottom: stats row
                Row(
                  children: [
                    _MiniStat(icon: Icons.paid_rounded, label: 'Per Task', value: Formatters.pkr(reward)),
                    _StatDivider(),
                    _MiniStat(icon: Icons.task_alt_rounded, label: 'Available', value: '$taskCount Tasks'),
                    _StatDivider(),
                    _MiniStat(
                      icon: user.subscriptionActive ? Icons.verified_rounded : Icons.lock_rounded,
                      label: 'Account',
                      value: user.subscriptionActive ? AppStrings.statusActive : AppStrings.statusLocked,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.7), size: 4.5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12.5.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.2.h),
          Text(
            label,
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.9), fontSize: 11.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 5.h, color: AppColors.white.withValues(alpha: 0.12));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SUBSCRIPTION BANNER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    // space for the floating card overlap
    final spacer = SizedBox(height: 4.h);

    if (user.subscriptionActive) return spacer;

    if (user.hasPendingSubscription) {
      return Column(
        children: [
          spacer,
          Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: NoticeBanner.warning(
              AppStrings.paymentUnderReviewMessage,
              title: AppStrings.paymentUnderReviewTitle,
            ),
          ),
        ],
      );
    }

    final price = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.subscriptionPrice);

    return Column(
      children: [
        spacer,
        Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: GestureDetector(
            onTap: () => context.push(Routes.subscribe),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.w),
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryDark.withValues(alpha: 0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.2),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(3.w),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.lock_open_rounded, color: AppColors.white, size: 5.5.w),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.subscribeBannerTitle,
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 15.sp),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          AppStrings.subscribeBannerMessage(Formatters.pkr(price)),
                          style: AppTextStyles.caption.copyWith(color: Colors.grey.shade500, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(2.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Subscribe',
                          style: TextStyle(color: AppColors.white, fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 1.w),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 4.w),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  TASK PREVIEW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final reward = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.videoReward);

    if (!vm.loaded && !vm.hasError) {
      return Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: SkeletonBox(height: 28.h),
          ),
        ),
      );
    }

    if (vm.hasError && vm.tasks.isEmpty) {
      return ErrorState(message: vm.errorMessage, onRetry: vm.load);
    }

    if (vm.tasks.isEmpty) {
      return const EmptyState(
        title: AppStrings.noTasksTitle,
        message: AppStrings.noTasksMessage,
        icon: Icons.video_library_outlined,
      );
    }

    return Column(
      children: vm.preview
          .map(
            (t) => Padding(
              padding: EdgeInsets.only(bottom: 2.5.h),
              child: TaskCard(
                task: t,
                reward: reward,
                locked: !user.canEarn,
                completed: vm.isCompleted(t.id),
                onTap: () => openTask(context, t),
              ),
            ),
          )
          .toList(),
    );
  }
}
