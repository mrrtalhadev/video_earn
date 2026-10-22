import '../../core/constants/app_constants.dart';
import 'model_utils.dart';
import 'order_status.dart';

class SubscriptionOrder {
  const SubscriptionOrder({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.priceAtSubmission,
    required this.transactionId,
    required this.proofId,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String uid;
  final String userName;
  final String userEmail;
  final int amount;
  final int priceAtSubmission;
  final String transactionId;
  final String proofId;
  final OrderStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  factory SubscriptionOrder.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return SubscriptionOrder(
      id: doc.id,
      uid: d.str(FsKeys.uid),
      userName: d.str(FsKeys.userName),
      userEmail: d.str(FsKeys.userEmail),
      amount: d.integer(FsKeys.amount),
      priceAtSubmission: d.integer(FsKeys.priceAtSubmission),
      transactionId: d.str(FsKeys.transactionId),
      proofId: d.str(FsKeys.proofId),
      status: OrderStatus.parse(d[FsKeys.status]),
      rejectionReason: d.strOrNull(FsKeys.rejectionReason),
      createdAt: d.date(FsKeys.createdAt),
      reviewedAt: d.date(FsKeys.reviewedAt),
      reviewedBy: d.strOrNull(FsKeys.reviewedBy),
    );
  }
}
