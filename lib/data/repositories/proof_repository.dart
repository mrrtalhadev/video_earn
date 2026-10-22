import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/payment_proof.dart';

/// Payment screenshots. Stored as compressed JPEG blobs in Firestore because
/// Firebase Storage needs the Blaze plan for new projects. Keep callers on
/// this interface so a Storage-backed implementation can be swapped in.
///
/// The proof id is always the id of the order it belongs to; the rules only
/// accept a proof created in the same write as a brand-new order.
abstract class ProofRepository {
  /// Adds the proof write to an order transaction.
  void attach(Transaction tx, {required String orderId, required String uid, required Uint8List bytes});

  /// Loads a proof by id (owner or admin only). Null if missing.
  Future<Uint8List?> load(String proofId);
}

class FirestoreProofRepository implements ProofRepository {
  FirestoreProofRepository(this._db);

  final FirebaseFirestore _db;

  @override
  void attach(Transaction tx, {required String orderId, required String uid, required Uint8List bytes}) {
    tx.set(_db.collection(FsCol.paymentProofs).doc(orderId), PaymentProof.createMap(uid, bytes));
  }

  @override
  Future<Uint8List?> load(String proofId) async {
    if (proofId.isEmpty) return null;
    final snap = await _db.collection(FsCol.paymentProofs).doc(proofId).get();
    if (!snap.exists) return null;
    final proof = PaymentProof.fromDoc(snap);
    return proof.bytes.isEmpty ? null : proof.bytes;
  }
}
