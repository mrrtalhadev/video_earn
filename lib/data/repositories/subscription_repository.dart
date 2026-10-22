import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/order_status.dart';
import '../models/referral_entry.dart';
import '../models/subscription_order.dart';
import '../models/wallet_transaction.dart';
import 'page_result.dart';
import 'proof_repository.dart';

abstract class SubscriptionRepository {
  /// Proof + pending order + `hasPendingSubscription=true`, atomically.
  /// [expectedPrice] is the price the user saw; if it changed meanwhile the
  /// submit is aborted so the user can review the new amount.
  Future<void> submit({
    required AppUser user,
    required int expectedPrice,
    required String transactionId,
    required Uint8List proofBytes,
  });

  /// The user's most recent order (live), or null.
  Stream<SubscriptionOrder?> watchLatestOrder(String uid);

  Future<List<SubscriptionOrder>> ordersForUser(String uid);

  // Admin
  Future<PageResult<SubscriptionOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter});
  Future<int> countSameTransactionId(String transactionId);
  Future<void> approve({required String orderId, required String adminUid});
  Future<void> reject({required String orderId, required String adminUid, required String reason});
}

class FirestoreSubscriptionRepository implements SubscriptionRepository {
  FirestoreSubscriptionRepository(this._db, this._proofs);

  final FirebaseFirestore _db;
  final ProofRepository _proofs;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection(FsCol.subscriptionOrders);
  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection(FsCol.users).doc(uid);
  DocumentReference<Map<String, dynamic>> get _settings => _db.collection(FsCol.settings).doc(FsCol.settingsDoc);

  @override
  Future<void> submit({
    required AppUser user,
    required int expectedPrice,
    required String transactionId,
    required Uint8List proofBytes,
  }) {
    final orderRef = _orders.doc();
    return _db.runTransaction<void>((tx) async {
      final settingsSnap = await tx.get(_settings);
      final userSnap = await tx.get(_user(user.uid));
      if (!settingsSnap.exists || !userSnap.exists) {
        throw const AppException(AppStrings.settingsNotLoaded);
      }
      final price = AppSettings.fromMap(settingsSnap.data()!).subscriptionPrice;
      if (price != expectedPrice) throw const AppException(AppStrings.priceChanged);
      final fresh = AppUser.fromDoc(userSnap);
      if (fresh.subscriptionActive) throw const AppException(AppStrings.alreadySubscribed);
      if (fresh.hasPendingSubscription) throw const AppException(AppStrings.errorAlreadyPending);
      if (fresh.isBlocked) throw const AppException(AppStrings.blockedMessage);

      _proofs.attach(tx, orderId: orderRef.id, uid: user.uid, bytes: proofBytes);
      tx.set(orderRef, {
        FsKeys.uid: user.uid,
        FsKeys.userName: fresh.name,
        FsKeys.userEmail: fresh.email,
        FsKeys.amount: price,
        FsKeys.priceAtSubmission: price,
        FsKeys.transactionId: transactionId.trim(),
        FsKeys.proofId: orderRef.id,
        FsKeys.status: OrderStatus.pending.name,
        FsKeys.createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(_user(user.uid), {FsKeys.hasPendingSubscription: true});
    }).withWriteTimeout();
  }

  @override
  Stream<SubscriptionOrder?> watchLatestOrder(String uid) => _orders
      .where(FsKeys.uid, isEqualTo: uid)
      .orderBy(FsKeys.createdAt, descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : SubscriptionOrder.fromDoc(s.docs.first));

  @override
  Future<List<SubscriptionOrder>> ordersForUser(String uid) async {
    final snap = await _orders
        .where(FsKeys.uid, isEqualTo: uid)
        .orderBy(FsKeys.createdAt, descending: true)
        .limit(50)
        .get();
    return snap.docs.map(SubscriptionOrder.fromDoc).toList();
  }

  @override
  Future<PageResult<SubscriptionOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) => fetchPage(
    _orders.where(FsKeys.status, isEqualTo: status.name).orderBy(FsKeys.createdAt, descending: true),
    SubscriptionOrder.fromDoc,
    startAfter: startAfter,
  );

  @override
  Future<int> countSameTransactionId(String transactionId) async {
    final agg = await _orders.where(FsKeys.transactionId, isEqualTo: transactionId).count().get();
    return agg.count ?? 0;
  }

  /// Re-reads the order inside the transaction and aborts unless still
  /// pending, so two admin devices can never approve twice. Pays the
  /// referral bonus exactly once (guarded by `referralBonusPaid`).
  @override
  Future<void> approve({required String orderId, required String adminUid}) {
    final orderRef = _orders.doc(orderId);
    return _db.runTransaction<void>((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw const AppException(AppStrings.errorNotFound);
      final order = SubscriptionOrder.fromDoc(orderSnap);
      if (order.status != OrderStatus.pending) throw const AppException(AppStrings.alreadyReviewed);

      final userSnap = await tx.get(_user(order.uid));
      final settingsSnap = await tx.get(_settings);
      if (!userSnap.exists) throw const AppException(AppStrings.errorNotFound);
      final user = AppUser.fromDoc(userSnap);
      final bonus = AppSettings.fromMap(settingsSnap.data() ?? const {}).referralBonus;

      final payReferral = user.referredBy != null && !user.referralBonusPaid && bonus > 0;
      AppUser? referrer;
      DocumentReference<Map<String, dynamic>>? referralEntryRef;
      var referralEntryExists = false;
      if (payReferral) {
        final refSnap = await tx.get(_user(user.referredBy!));
        if (refSnap.exists) referrer = AppUser.fromDoc(refSnap);
        referralEntryRef = _db
            .collection(FsCol.referrals)
            .doc(user.referredBy)
            .collection(FsCol.referred)
            .doc(user.uid);
        referralEntryExists = (await tx.get(referralEntryRef)).exists;
      }

      tx.update(orderRef, {
        FsKeys.status: OrderStatus.approved.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
      });
      tx.update(_user(user.uid), {
        FsKeys.subscriptionActive: true,
        FsKeys.subscriptionActivatedAt: FieldValue.serverTimestamp(),
        FsKeys.hasPendingSubscription: false,
        if (referrer != null) FsKeys.referralBonusPaid: true,
      });
      tx.set(
        _user(user.uid).collection(FsCol.transactions).doc(TxIds.subscription(orderId)),
        WalletTransaction.toCreateMap(
          type: TxType.subscriptionPayment,
          amount: 0,
          balanceAfter: user.balance,
          refId: orderId,
          title: AppStrings.txSubscription,
          createdAt: FieldValue.serverTimestamp(),
        ),
      );

      if (referrer != null) {
        final newBalance = referrer.balance + bonus;
        tx.update(_user(referrer.uid), {
          FsKeys.balance: newBalance,
          FsKeys.totalReferralEarned: referrer.totalReferralEarned + bonus,
          FsKeys.referralCount: referrer.referralCount + 1,
        });
        tx.set(
          _user(referrer.uid).collection(FsCol.transactions).doc(TxIds.referral(user.uid)),
          WalletTransaction.toCreateMap(
            type: TxType.referralBonus,
            amount: bonus,
            balanceAfter: newBalance,
            refId: user.uid,
            title: AppStrings.txReferralBonus,
            createdAt: FieldValue.serverTimestamp(),
          ),
        );
        // Only the referee can create the entry (at signup); admin updates it.
        if (referralEntryExists) {
          tx.update(referralEntryRef!, {
            FsKeys.status: ReferralEntry.statusBonusPaid,
            FsKeys.bonus: bonus,
            FsKeys.paidAt: FieldValue.serverTimestamp(),
          });
        }
      }
    }).withWriteTimeout();
  }

  @override
  Future<void> reject({required String orderId, required String adminUid, required String reason}) {
    final orderRef = _orders.doc(orderId);
    return _db.runTransaction<void>((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw const AppException(AppStrings.errorNotFound);
      final order = SubscriptionOrder.fromDoc(orderSnap);
      if (order.status != OrderStatus.pending) throw const AppException(AppStrings.alreadyReviewed);

      tx.update(orderRef, {
        FsKeys.status: OrderStatus.rejected.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
        FsKeys.rejectionReason: reason.trim(),
      });
      tx.update(_user(order.uid), {FsKeys.hasPendingSubscription: false});
    }).withWriteTimeout();
  }
}
