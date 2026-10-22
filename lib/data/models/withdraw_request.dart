import '../../core/constants/app_constants.dart';
import 'model_utils.dart';
import 'order_status.dart';

class WithdrawRequest {
  const WithdrawRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.amount,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.status,
    this.rejectionReason,
    this.adminTransferRef,
    this.prevLastWithdrawAt,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String uid;
  final String userName;
  final int amount;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final OrderStatus status;
  final String? rejectionReason;
  final String? adminTransferRef;
  final DateTime? prevLastWithdrawAt;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  factory WithdrawRequest.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return WithdrawRequest(
      id: doc.id,
      uid: d.str(FsKeys.uid),
      userName: d.str(FsKeys.userName),
      amount: d.integer(FsKeys.amount),
      accountHolderName: d.str(FsKeys.accountHolderName),
      bankName: d.str(FsKeys.bankName),
      accountNumber: d.str(FsKeys.accountNumber),
      status: OrderStatus.parse(d[FsKeys.status]),
      rejectionReason: d.strOrNull(FsKeys.rejectionReason),
      adminTransferRef: d.strOrNull(FsKeys.adminTransferRef),
      prevLastWithdrawAt: d.date(FsKeys.prevLastWithdrawAt),
      createdAt: d.date(FsKeys.createdAt),
      reviewedAt: d.date(FsKeys.reviewedAt),
    );
  }
}
