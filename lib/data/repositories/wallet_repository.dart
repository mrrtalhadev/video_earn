import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/wallet_transaction.dart';
import 'page_result.dart';

abstract class WalletRepository {
  Future<List<WalletTransaction>> recent(String uid, {int limit = AppConstants.recentTransactions});

  /// Ledger page, newest first, optionally restricted to [types].
  Future<PageResult<WalletTransaction>> page(String uid, {List<TxType>? types, JsonDoc? startAfter});
}

class FirestoreWalletRepository implements WalletRepository {
  FirestoreWalletRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _ledger(String uid) =>
      _db.collection(FsCol.users).doc(uid).collection(FsCol.transactions);

  @override
  Future<List<WalletTransaction>> recent(String uid, {int limit = AppConstants.recentTransactions}) async {
    final snap = await _ledger(uid).orderBy(FsKeys.createdAt, descending: true).limit(limit).get();
    return snap.docs.map(WalletTransaction.fromDoc).toList();
  }

  @override
  Future<PageResult<WalletTransaction>> page(String uid, {List<TxType>? types, JsonDoc? startAfter}) {
    JsonQuery q = _ledger(uid);
    if (types != null && types.isNotEmpty) {
      q = q.where(FsKeys.type, whereIn: types.map((t) => t.value).toList());
    }
    q = q.orderBy(FsKeys.createdAt, descending: true);
    return fetchPage(q, WalletTransaction.fromDoc, startAfter: startAfter);
  }
}
