import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet_transaction.dart';

/// One ledger row: icon by type, title, date, signed amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (tx.type) {
      TxType.taskReward => (Icons.play_circle_fill_rounded, AppStrings.txTaskReward),
      TxType.referralBonus => (Icons.card_giftcard_rounded, AppStrings.txReferralBonus),
      TxType.withdrawHold => (Icons.account_balance_wallet_rounded, AppStrings.txWithdrawHold),
      TxType.withdrawRefund => (Icons.undo_rounded, AppStrings.txWithdrawRefund),
      TxType.subscriptionPayment => (Icons.verified_rounded, AppStrings.txSubscription),
      TxType.promotePayment => (Icons.campaign_rounded, AppStrings.txPromote),
    };
    final color = tx.amount > 0
        ? AppColors.success
        : tx.amount < 0
        ? AppColors.error
        : AppColors.textSecondary;
    final subtitle = tx.type == TxType.taskReward && tx.title.isNotEmpty ? tx.title : label;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 5.5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                if (subtitle != label)
                  Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(Formatters.dateTime(tx.createdAt), style: AppTextStyles.caption),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.amount == 0 ? '—' : Formatters.pkrSigned(tx.amount),
                style: AppTextStyles.subtitle.copyWith(color: color),
              ),
              Text(AppStrings.balanceAfter(Formatters.pkr(tx.balanceAfter)), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
