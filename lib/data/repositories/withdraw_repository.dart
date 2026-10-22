import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/date_utils.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/order_status.dart';
import '../models/wallet_transaction.dart';
import '../models/withdraw_request.dart';
import 'page_result.dart';

abstract class WithdrawRepository {
  /// Request + balance hold + ledger row, atomically (rules: validWithdrawHold).
  Future<void> submit({
    required String uid,
    required int amount,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
  });

  Future<PageResult<WithdrawRequest>> pageForUser(String uid, {JsonDoc? startAfter});

  // Admin
  Future<PageResult<WithdrawRequest>> pageByStatus(OrderStatus status, {JsonDoc? startAfter});
  Future<void> approve({required String requestId, required String adminUid, String? transferRef});
  Future<void> reject({required String requestId, required String adminUid, required String reason});
}

class FirestoreWithdrawRepository implements WithdrawRepository {
  FirestoreWithdrawRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection(FsCol.withdrawRequests);
  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection(FsCol.users).doc(uid);

  @override
  Future<void> submit({
    required String uid,
    required int amount,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
  }) {
    final requestRef = _requests.doc();
    return _db.runTransaction<void>((tx) async {
      final userSnap = await tx.get(_user(uid));
      final settingsSnap = await tx.get(_db.collection(FsCol.settings).doc(FsCol.settingsDoc));
      if (!userSnap.exists || !settingsSnap.exists) {
        throw const AppException(AppStrings.settingsNotLoaded);
      }
      final user = AppUser.fromDoc(userSnap);
      final cfg = AppSettings.fromMap(settingsSnap.data()!);

      // Same checks as the rules, for friendly messages.
      if (!user.canEarn) throw const AppException(AppStrings.errorNotSubscribed);
      if (amount < cfg.minWithdraw) {
        throw AppException(AppStrings.withdrawBalanceTooLow(cfg.minWithdraw.toString()));
      }
      if (amount > user.balance) throw const AppException(AppStrings.errorInsufficientBalance);
      if (AppDateUtils.inCooldown(user.lastWithdrawAt, cfg.withdrawCooldownDays)) {
        throw const AppException(AppStrings.errorCooldown);
      }

      final newBalance = user.balance - amount;
      tx.set(requestRef, {
        FsKeys.uid: uid,
        FsKeys.userName: user.name,
        FsKeys.amount: amount,
        FsKeys.accountHolderName: accountHolderName.trim(),
        FsKeys.bankName: bankName.trim(),
        FsKeys.accountNumber: accountNumber,
        FsKeys.status: OrderStatus.pending.name,
        // Copy the raw Timestamp: the rules compare it for exact equality.
        FsKeys.prevLastWithdrawAt: userSnap.data()![FsKeys.lastWithdrawAt],
        FsKeys.createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(_user(uid), {
        FsKeys.balance: newBalance,
        FsKeys.pendingWithdraw: user.pendingWithdraw + amount,
        FsKeys.lastWithdrawAt: FieldValue.serverTimestamp(),
        FsKeys.lastWithdrawRequestId: requestRef.id,
      });
      tx.set(
        _user(uid).collection(FsCol.transactions).doc(TxIds.withdraw(requestRef.id)),
        WalletTransaction.toCreateMap(
          type: TxType.withdrawHold,
          amount: -amount,
          balanceAfter: newBalance,
          refId: requestRef.id,
          title: AppStrings.txWithdrawHold,
          createdAt: FieldValue.serverTimestamp(),
        ),
      );
    }).withWriteTimeout();
  }

  @override
  Future<PageResult<WithdrawRequest>> pageForUser(String uid, {JsonDoc? startAfter}) => fetchPage(
    _requests.where(FsKeys.uid, isEqualTo: uid).orderBy(FsKeys.createdAt, descending: true),
    WithdrawRequest.fromDoc,
    startAfter: startAfter,
  );

  @override
  Future<PageResult<WithdrawRequest>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) => fetchPage(
    _requests.where(FsKeys.status, isEqualTo: status.name).orderBy(FsKeys.createdAt, descending: true),
    WithdrawRequest.fromDoc,
    startAfter: startAfter,
  );

  Future<(WithdrawRequest, AppUser, Object?)> _readPending(Transaction tx, String requestId) async {
    final snap = await tx.get(_requests.doc(requestId));
    if (!snap.exists) throw const AppException(AppStrings.errorNotFound);
    final request = WithdrawRequest.fromDoc(snap);
    if (request.status != OrderStatus.pending) throw const AppException(AppStrings.alreadyReviewed);
    final userSnap = await tx.get(_user(request.uid));
    if (!userSnap.exists) throw const AppException(AppStrings.errorNotFound);
    return (request, AppUser.fromDoc(userSnap), snap.data()![FsKeys.prevLastWithdrawAt]);
  }

  @override
  Future<void> approve({required String requestId, required String adminUid, String? transferRef}) {
    return _db.runTransaction<void>((tx) async {
      final (request, user, _) = await _readPending(tx, requestId);
      final ref = transferRef?.trim();
      tx.update(_requests.doc(requestId), {
        FsKeys.status: OrderStatus.approved.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
        if (ref != null && ref.isNotEmpty) FsKeys.adminTransferRef: ref,
      });
      tx.update(_user(user.uid), {
        FsKeys.pendingWithdraw: user.pendingWithdraw - request.amount,
        FsKeys.totalWithdrawn: user.totalWithdrawn + request.amount,
      });
    }).withWriteTimeout();
  }

  /// Refunds the hold. The weekly slot is given back (lastWithdrawAt restored
  /// to prevLastWithdrawAt) only if this request is still the user's latest,
  /// so a newer request's cooldown is never wiped.
  @override
  Future<void> reject({required String requestId, required String adminUid, required String reason}) {
    return _db.runTransaction<void>((tx) async {
      final (request, user, prevLastWithdrawAt) = await _readPending(tx, requestId);
      final newBalance = user.balance + request.amount;
      tx.update(_requests.doc(requestId), {
        FsKeys.status: OrderStatus.rejected.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
        FsKeys.rejectionReason: reason.trim(),
      });
      tx.update(_user(user.uid), {
        FsKeys.balance: newBalance,
        FsKeys.pendingWithdraw: user.pendingWithdraw - request.amount,
        if (user.lastWithdrawRequestId == request.id) FsKeys.lastWithdrawAt: prevLastWithdrawAt,
      });
      tx.set(
        _user(user.uid).collection(FsCol.transactions).doc(TxIds.refund(requestId)),
        WalletTransaction.toCreateMap(
          type: TxType.withdrawRefund,
          amount: request.amount,
          balanceAfter: newBalance,
          refId: requestId,
          title: AppStrings.txWithdrawRefund,
          createdAt: FieldValue.serverTimestamp(),
        ),
      );
    }).withWriteTimeout();
  }
}
