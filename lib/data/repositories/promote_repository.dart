import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/youtube_utils.dart';
import '../models/app_user.dart';
import '../models/order_status.dart';
import '../models/promote_order.dart';
import '../models/promote_package.dart';
import '../models/video_task.dart';
import '../models/wallet_transaction.dart';
import 'page_result.dart';
import 'proof_repository.dart';

abstract class PromoteRepository {
  Future<List<PromotePackage>> fetchPackages({bool activeOnly = true});
  Future<void> savePackage(PromotePackage package);

  /// Deletes the package, or deactivates it if orders reference it.
  /// Returns true if it was deleted.
  Future<bool> deleteOrDeactivatePackage(String id);

  Future<void> submitOrder({
    required String uid,
    required PromotePackage package,
    required String videoUrl,
    required String videoId,
    required String title,
    required String description,
    required String transactionId,
    required Uint8List proofBytes,
  });

  Future<PageResult<PromoteOrder>> pageForUser(String uid, {JsonDoc? startAfter});

  // Admin
  Future<PageResult<PromoteOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter});
  Future<int> countSameTransactionId(String transactionId);

  /// Approves and publishes the video as a task for the package period.
  /// [durationSeconds] comes from the admin's "Load & verify" step.
  Future<void> approve({required String orderId, required String adminUid, required int durationSeconds});
  Future<void> reject({required String orderId, required String adminUid, required String reason});
}

class FirestorePromoteRepository implements PromoteRepository {
  FirestorePromoteRepository(this._db, this._proofs);

  final FirebaseFirestore _db;
  final ProofRepository _proofs;

  CollectionReference<Map<String, dynamic>> get _packages => _db.collection(FsCol.promotePackages);
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection(FsCol.promoteOrders);

  @override
  Future<List<PromotePackage>> fetchPackages({bool activeOnly = true}) async {
    JsonQuery q = _packages;
    if (activeOnly) q = q.where(FsKeys.isActive, isEqualTo: true);
    final snap = await q.orderBy(FsKeys.sortOrder).limit(50).get();
    return snap.docs.map(PromotePackage.fromDoc).toList();
  }

  @override
  Future<void> savePackage(PromotePackage package) {
    final ref = package.id.isEmpty ? _packages.doc() : _packages.doc(package.id);
    return ref.set(package.toMap()).withWriteTimeout();
  }

  @override
  Future<bool> deleteOrDeactivatePackage(String id) async {
    final used = await _orders.where(FsKeys.packageId, isEqualTo: id).limit(1).count().get();
    if ((used.count ?? 0) > 0) {
      await _packages.doc(id).update({FsKeys.isActive: false}).withWriteTimeout();
      return false;
    }
    await _packages.doc(id).delete().withWriteTimeout();
    return true;
  }

  @override
  Future<void> submitOrder({
    required String uid,
    required PromotePackage package,
    required String videoUrl,
    required String videoId,
    required String title,
    required String description,
    required String transactionId,
    required Uint8List proofBytes,
  }) {
    final orderRef = _orders.doc();
    return _db.runTransaction<void>((tx) async {
      final pkgSnap = await tx.get(_packages.doc(package.id));
      final userSnap = await tx.get(_db.collection(FsCol.users).doc(uid));
      if (!pkgSnap.exists || !userSnap.exists) throw const AppException(AppStrings.errorNotFound);
      final pkg = PromotePackage.fromDoc(pkgSnap);
      if (!pkg.isActive) throw const AppException(AppStrings.noPackages);
      if (pkg.price != package.price || pkg.durationDays != package.durationDays) {
        throw const AppException(AppStrings.priceChanged);
      }
      final user = AppUser.fromDoc(userSnap);
      if (user.isBlocked) throw const AppException(AppStrings.blockedMessage);

      _proofs.attach(tx, orderId: orderRef.id, uid: uid, bytes: proofBytes);
      tx.set(orderRef, {
        FsKeys.uid: uid,
        FsKeys.userName: user.name,
        FsKeys.videoUrl: videoUrl.trim(),
        FsKeys.youtubeVideoId: videoId,
        FsKeys.videoTitle: title.trim(),
        FsKeys.videoDescription: description.trim(),
        FsKeys.packageId: pkg.id,
        FsKeys.packageName: pkg.name,
        FsKeys.price: pkg.price,
        FsKeys.durationDays: pkg.durationDays,
        FsKeys.transactionId: transactionId.trim(),
        FsKeys.proofId: orderRef.id,
        FsKeys.status: OrderStatus.pending.name,
        FsKeys.createdAt: FieldValue.serverTimestamp(),
      });
    }).withWriteTimeout();
  }

  @override
  Future<PageResult<PromoteOrder>> pageForUser(String uid, {JsonDoc? startAfter}) => fetchPage(
    _orders.where(FsKeys.uid, isEqualTo: uid).orderBy(FsKeys.createdAt, descending: true),
    PromoteOrder.fromDoc,
    startAfter: startAfter,
  );

  @override
  Future<PageResult<PromoteOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) => fetchPage(
    _orders.where(FsKeys.status, isEqualTo: status.name).orderBy(FsKeys.createdAt, descending: true),
    PromoteOrder.fromDoc,
    startAfter: startAfter,
  );

  @override
  Future<int> countSameTransactionId(String transactionId) async {
    final agg = await _orders.where(FsKeys.transactionId, isEqualTo: transactionId).count().get();
    return agg.count ?? 0;
  }

  @override
  Future<void> approve({required String orderId, required String adminUid, required int durationSeconds}) {
    final orderRef = _orders.doc(orderId);
    final taskRef = _db.collection(FsCol.tasks).doc();
    return _db.runTransaction<void>((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw const AppException(AppStrings.errorNotFound);
      final order = PromoteOrder.fromDoc(orderSnap);
      if (order.status != OrderStatus.pending) throw const AppException(AppStrings.alreadyReviewed);
      final userRef = _db.collection(FsCol.users).doc(order.uid);
      final userSnap = await tx.get(userRef);
      final balance = userSnap.exists ? AppUser.fromDoc(userSnap).balance : 0;

      final now = DateTime.now();
      final start = Timestamp.fromDate(now);
      final end = Timestamp.fromDate(now.add(Duration(days: order.durationDays)));

      tx.set(taskRef, {
        FsKeys.title: order.videoTitle,
        FsKeys.description: order.videoDescription,
        FsKeys.youtubeVideoId: order.youtubeVideoId,
        FsKeys.youtubeUrl: YoutubeUtils.watchUrl(order.youtubeVideoId),
        FsKeys.thumbnailUrl: YoutubeUtils.thumbnailUrl(order.youtubeVideoId),
        FsKeys.durationSeconds: durationSeconds,
        FsKeys.source: TaskSource.promote.name,
        FsKeys.ownerUid: order.uid,
        FsKeys.promoteOrderId: order.id,
        FsKeys.isActive: true,
        FsKeys.startAt: start,
        FsKeys.expiresAt: end,
        FsKeys.order: 0,
        FsKeys.createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(orderRef, {
        FsKeys.status: OrderStatus.approved.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
        FsKeys.taskId: taskRef.id,
        FsKeys.startAt: start,
        FsKeys.expiresAt: end,
      });
      if (userSnap.exists) {
        tx.set(
          userRef.collection(FsCol.transactions).doc(TxIds.promote(order.id)),
          WalletTransaction.toCreateMap(
            type: TxType.promotePayment,
            amount: 0,
            balanceAfter: balance,
            refId: order.id,
            title: AppStrings.txPromote,
            createdAt: FieldValue.serverTimestamp(),
          ),
        );
      }
    }).withWriteTimeout();
  }

  @override
  Future<void> reject({required String orderId, required String adminUid, required String reason}) {
    final orderRef = _orders.doc(orderId);
    return _db.runTransaction<void>((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) throw const AppException(AppStrings.errorNotFound);
      if (PromoteOrder.fromDoc(snap).status != OrderStatus.pending) {
        throw const AppException(AppStrings.alreadyReviewed);
      }
      tx.update(orderRef, {
        FsKeys.status: OrderStatus.rejected.name,
        FsKeys.reviewedAt: FieldValue.serverTimestamp(),
        FsKeys.reviewedBy: adminUid,
        FsKeys.rejectionReason: reason.trim(),
      });
    }).withWriteTimeout();
  }
}
