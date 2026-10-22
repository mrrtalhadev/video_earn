import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../../data/models/withdraw_request.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../data/repositories/withdraw_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/paged_list.dart';
import '../../../viewmodels/user/history_view_model.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/transaction_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HistoryViewModel(
        uid: ctx.read<SessionViewModel>().uid!,
        wallet: ctx.read<WalletRepository>(),
        subscriptions: ctx.read<SubscriptionRepository>(),
        promote: ctx.read<PromoteRepository>(),
        withdrawals: ctx.read<WithdrawRepository>(),
      ),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          body: Column(
            children: [
              // ── header with tabs ──
              Container(
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 2.h),
                      child: Row(
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
                            AppStrings.historyTitle,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // tab bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3.w),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2.5.w),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppColors.white,
                          unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
                          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp),
                          tabs: const [
                            Tab(text: AppStrings.tabEarnings),
                            Tab(text: AppStrings.tabDeposits),
                            Tab(text: AppStrings.tabWithdrawals),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── tab content ──
              Expanded(
                child: TabBarView(
                  children: [
                    _LazyTab<WalletTransaction>(
                      list: vm.earnings,
                      emptyTitle: AppStrings.noEarnings,
                      emptyMessage: AppStrings.noEarningsMessage,
                      emptyIcon: Icons.savings_rounded,
                      builder: (_, tx) => _EarningCard(tx: tx),
                    ),
                    _LazyTab<DepositEntry>(
                      list: vm.deposits,
                      emptyTitle: AppStrings.noDeposits,
                      emptyMessage: AppStrings.noDepositsMessage,
                      emptyIcon: Icons.account_balance_wallet_rounded,
                      builder: (_, d) => _DepositCard(entry: d),
                    ),
                    _LazyTab<WithdrawRequest>(
                      list: vm.withdrawList,
                      emptyTitle: AppStrings.noWithdrawals,
                      emptyMessage: AppStrings.noWithdrawalsMessage,
                      emptyIcon: Icons.account_balance_rounded,
                      builder: (_, w) => _WithdrawCard(request: w),
                    ),
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

class _LazyTab<T> extends StatelessWidget {
  const _LazyTab({
    required this.list,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.builder,
  });

  final PagedList<T> list;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) {
    if (!list.loaded && !list.isLoading && list.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => list.ensureLoaded());
    }
    return PagedListView<T>(
      list: list,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
      itemBuilder: builder,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  EARNING CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _EarningCard extends StatelessWidget {
  const _EarningCard({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TransactionTile(tx: tx),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DEPOSIT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _DepositCard extends StatelessWidget {
  const _DepositCard({required this.entry});
  final DepositEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.5.w),
                ),
                child: Icon(Icons.south_west_rounded, color: AppColors.primary, size: 4.5.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(entry.title, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
              ),
              StatusChip.order(entry.status),
            ],
          ),
          SizedBox(height: 1.2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(3.w)),
            child: Row(
              children: [
                _InfoItem(icon: Icons.payments_rounded, value: Formatters.pkr(entry.amount)),
                Container(width: 1, height: 3.h, color: Colors.grey.shade200),
                _InfoItem(icon: Icons.receipt_long_rounded, value: entry.transactionId),
                Container(width: 1, height: 3.h, color: Colors.grey.shade200),
                _InfoItem(icon: Icons.calendar_today_rounded, value: Formatters.dateTime(entry.createdAt)),
              ],
            ),
          ),
          if (entry.status == OrderStatus.rejected && entry.rejectionReason != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2.5.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 4.w, color: AppColors.error),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      AppStrings.rejectionReason(entry.rejectionReason!),
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  WITHDRAW CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _WithdrawCard extends StatelessWidget {
  const _WithdrawCard({required this.request});
  final WithdrawRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.5.w),
                ),
                child: Icon(Icons.north_east_rounded, color: AppColors.primary, size: 4.5.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  Formatters.pkr(request.amount),
                  style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w900, fontSize: 17.sp),
                ),
              ),
              StatusChip.order(request.status),
            ],
          ),
          SizedBox(height: 1.2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(3.w)),
            child: Row(
              children: [
                _InfoItem(icon: Icons.account_balance_rounded, value: '${request.bankName} · ${request.accountNumber}'),
                Container(width: 1, height: 3.h, color: Colors.grey.shade200),
                _InfoItem(icon: Icons.calendar_today_rounded, value: Formatters.dateTime(request.createdAt)),
              ],
            ),
          ),
          if (request.status == OrderStatus.rejected && request.rejectionReason != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2.5.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 4.w, color: AppColors.error),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      AppStrings.rejectionReason(request.rejectionReason!),
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  INFO ITEM — used inside detail strips
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 3.5.w, color: Colors.grey.shade400),
          SizedBox(width: 1.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
