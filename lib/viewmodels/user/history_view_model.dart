import '../../core/constants/app_strings.dart';
import '../../data/models/order_status.dart';
import '../../data/models/promote_order.dart';
import '../../data/models/subscription_order.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/models/withdraw_request.dart';
import '../../data/repositories/page_result.dart';
import '../../data/repositories/promote_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/withdraw_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';

/// A subscription or promote payment, unified for the Deposits tab.
class DepositEntry {
  const DepositEntry({
    required this.title,
    required this.amount,
    required this.status,
    required this.transactionId,
    this.createdAt,
    this.rejectionReason,
  });

  final String title;
  final int amount;
  final OrderStatus status;
  final String transactionId;
  final DateTime? createdAt;
  final String? rejectionReason;
}

class HistoryViewModel extends BaseViewModel {
  HistoryViewModel({
    required String uid,
    required WalletRepository wallet,
    required SubscriptionRepository subscriptions,
    required PromoteRepository promote,
    required WithdrawRepository withdrawals,
  }) {
    earnings = PagedList<WalletTransaction>(
      (cursor) => wallet.page(uid, types: const [TxType.taskReward, TxType.referralBonus], startAfter: cursor),
      notify,
    );
    withdrawList = PagedList<WithdrawRequest>((cursor) => withdrawals.pageForUser(uid, startAfter: cursor), notify);
    // Deposits come from two collections and are few per user: load both
    // (bounded) and merge newest first as a single page.
    deposits = PagedList<DepositEntry>((_) async {
      final results = await Future.wait([subscriptions.ordersForUser(uid), promote.pageForUser(uid)]);
      final subs = results[0] as List<SubscriptionOrder>;
      final promos = (results[1] as PageResult<PromoteOrder>).items;
      final entries = <DepositEntry>[
        for (final o in subs)
          DepositEntry(
            title: AppStrings.subscriptionPayment,
            amount: o.amount,
            status: o.status,
            transactionId: o.transactionId,
            createdAt: o.createdAt,
            rejectionReason: o.rejectionReason,
          ),
        for (final o in promos)
          DepositEntry(
            title: AppStrings.promotePayment(o.packageName),
            amount: o.price,
            status: o.status,
            transactionId: o.transactionId,
            createdAt: o.createdAt,
            rejectionReason: o.rejectionReason,
          ),
      ]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      return PageResult(items: entries, cursor: null, hasMore: false);
    }, notify);
  }

  late final PagedList<WalletTransaction> earnings;
  late final PagedList<DepositEntry> deposits;
  late final PagedList<WithdrawRequest> withdrawList;
}
