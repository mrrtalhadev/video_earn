import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

enum TxType {
  taskReward('task_reward'),
  referralBonus('referral_bonus'),
  withdrawHold('withdraw_hold'),
  withdrawRefund('withdraw_refund'),
  subscriptionPayment('subscription_payment'),
  promotePayment('promote_payment');

  const TxType(this.value);
  final String value;

  static TxType parse(Object? v) => TxType.values.firstWhere((t) => t.value == v, orElse: () => TxType.taskReward);
}

/// Deterministic ledger ids so a duplicate write is impossible.
abstract final class TxIds {
  static String task(String taskId) => 'task_$taskId';
  static String withdraw(String requestId) => 'wd_$requestId';
  static String refund(String requestId) => 'refund_$requestId';
  static String referral(String refereeUid) => 'ref_$refereeUid';
  static String subscription(String orderId) => 'sub_$orderId';
  static String promote(String orderId) => 'promo_$orderId';
}

/// `users/{uid}/transactions/{txId}` ledger row.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.refId,
    required this.title,
    this.createdAt,
  });

  final String id;
  final TxType type;

  /// Signed effect on balance.
  final int amount;
  final int balanceAfter;
  final String refId;
  final String title;
  final DateTime? createdAt;

  factory WalletTransaction.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return WalletTransaction(
      id: doc.id,
      type: TxType.parse(d[FsKeys.type]),
      amount: d.integer(FsKeys.amount),
      balanceAfter: d.integer(FsKeys.balanceAfter),
      refId: d.str(FsKeys.refId),
      title: d.str(FsKeys.title),
      createdAt: d.date(FsKeys.createdAt),
    );
  }

  static Map<String, dynamic> toCreateMap({
    required TxType type,
    required int amount,
    required int balanceAfter,
    required String refId,
    required String title,
    required Object createdAt,
  }) => {
    FsKeys.type: type.value,
    FsKeys.amount: amount,
    FsKeys.balanceAfter: balanceAfter,
    FsKeys.refId: refId,
    FsKeys.title: title,
    FsKeys.createdAt: createdAt,
  };
}
