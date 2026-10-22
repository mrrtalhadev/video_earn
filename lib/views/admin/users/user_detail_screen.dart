import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/repositories/withdraw_repository.dart';
import '../../../viewmodels/admin/admin_users_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/copyable_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/user_avatar.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => UserDetailViewModel(
        uid: uid,
        users: ctx.read<AdminUserRepository>(),
        subscriptions: ctx.read<SubscriptionRepository>(),
        withdrawals: ctx.read<WithdrawRepository>(),
        promote: ctx.read<PromoteRepository>(),
      ),
      child: const _UserDetailView(),
    );
  }
}

class _UserDetailView extends StatelessWidget {
  const _UserDetailView();

  Future<void> _toggleBlock(BuildContext context, AppUser user) async {
    final vm = context.read<UserDetailViewModel>();
    final block = !user.isBlocked;
    final ok = await ConfirmDialog.show(
      context,
      message: block ? AppStrings.blockConfirm : AppStrings.unblockConfirm,
      confirmLabel: block ? AppStrings.blockUser : AppStrings.unblockUser,
      destructive: block,
    );
    if (!ok) return;
    final done = await vm.setBlocked(block);
    if (!context.mounted) return;
    done
        ? AppSnackbars.success(context, block ? AppStrings.userBlocked : AppStrings.userUnblocked)
        : AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailViewModel>();
    final user = vm.user;

    Widget body;
    if (vm.userError != null && user == null) {
      body = ErrorState(message: vm.userError);
    } else if (!vm.userLoaded) {
      body = const SkeletonList();
    } else if (user == null) {
      body = const EmptyState(
        title: AppStrings.userNotFound,
        message: AppStrings.errorNotFound,
        icon: Icons.person_off_rounded,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.loadHistory,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 7.w),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppTextStyles.title),
                            Wrap(
                              spacing: 1.5.w,
                              children: [
                                if (user.isBlocked) StatusChip.negative(AppStrings.statusBlocked),
                                user.subscriptionActive
                                    ? StatusChip.positive(AppStrings.statusSubscribed)
                                    : StatusChip.neutral(AppStrings.statusNotSubscribed),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  CopyableRow(label: AppStrings.email, value: user.email),
                  CopyableRow(label: AppStrings.phone, value: user.phone),
                  InfoRow(label: AppStrings.joined, value: Formatters.dateTime(user.createdAt)),
                  InfoRow(
                    label: AppStrings.subscription,
                    value: user.subscriptionActive
                        ? Formatters.dateTime(user.subscriptionActivatedAt)
                        : (user.hasPendingSubscription ? AppStrings.statusPending : AppStrings.statusNotSubscribed),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: AppStrings.balances),
            AppCard(
              child: Column(
                children: [
                  InfoRow(label: AppStrings.availableBalance, value: Formatters.pkr(user.balance)),
                  InfoRow(label: AppStrings.totalEarned, value: Formatters.pkr(user.totalEarned)),
                  InfoRow(label: AppStrings.referralEarnings, value: Formatters.pkr(user.totalReferralEarned)),
                  InfoRow(label: AppStrings.totalWithdrawn, value: Formatters.pkr(user.totalWithdrawn)),
                  InfoRow(label: AppStrings.pendingWithdraw, value: Formatters.pkr(user.pendingWithdraw)),
                  InfoRow(label: AppStrings.completedTasks, value: Formatters.number(user.completedTasksCount)),
                ],
              ),
            ),
            const SectionHeader(title: AppStrings.referralInfo),
            AppCard(
              child: Column(
                children: [
                  InfoRow(label: AppStrings.referralCode, value: user.referralCode),
                  InfoRow(label: AppStrings.referredByLabel, value: user.referredByCode ?? '—'),
                  InfoRow(label: AppStrings.referralsCount, value: Formatters.number(user.referralCount)),
                ],
              ),
            ),
            ..._history(vm),
            SizedBox(height: 2.h),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: user.isBlocked ? AppColors.success : AppColors.error,
                side: BorderSide(color: user.isBlocked ? AppColors.success : AppColors.error),
              ),
              onPressed: vm.isLoading ? null : () => _toggleBlock(context, user),
              icon: Icon(user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded),
              label: Text(user.isBlocked ? AppStrings.unblockUser : AppStrings.blockUser),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarX(title: AppStrings.userDetail),
      body: SafeArea(child: body),
    );
  }

  List<Widget> _history(UserDetailViewModel vm) {
    if (vm.historyLoading) return [SizedBox(height: 2.h), const SkeletonList(count: 2)];
    if (vm.historyError != null) return [ErrorState(message: vm.historyError, onRetry: vm.loadHistory)];

    Widget row(String title, String subtitle, Widget chip) => Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          chip,
        ],
      ),
    );

    Widget section(String title, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        AppCard(
          child: rows.isEmpty ? Text(AppStrings.noItems, style: AppTextStyles.caption) : Column(children: rows),
        ),
      ],
    );

    return [
      section(AppStrings.depositHistory, [
        for (final o in vm.deposits)
          row(
            Formatters.pkr(o.amount),
            '${o.transactionId} · ${Formatters.dateTime(o.createdAt)}',
            StatusChip.order(o.status),
          ),
      ]),
      section(AppStrings.withdrawHistory, [
        for (final w in vm.withdraws)
          row(
            Formatters.pkr(w.amount),
            '${w.bankName} · ${Formatters.dateTime(w.createdAt)}',
            StatusChip.order(w.status),
          ),
      ]),
      section('${AppStrings.promoteUsage}: ${vm.promotes.isEmpty ? AppStrings.no : AppStrings.yes}', [
        for (final p in vm.promotes)
          row(
            p.videoTitle,
            '${p.packageName} · ${Formatters.pkr(p.price)} · ${Formatters.dateTime(p.createdAt)}',
            StatusChip.order(p.status),
          ),
      ]),
    ];
  }
}
