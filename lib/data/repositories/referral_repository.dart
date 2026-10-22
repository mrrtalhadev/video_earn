import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/referral_entry.dart';

abstract class ReferralRepository {
  /// Returns the uid that owns [code], or null if the code does not exist.
  Future<String?> ownerOfCode(String code);

  /// People referred by [uid], newest first.
  Future<List<ReferralEntry>> referredBy(String uid);
}

class FirestoreReferralRepository implements ReferralRepository {
  FirestoreReferralRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<String?> ownerOfCode(String code) async {
    final snap = await _db.collection(FsCol.referralCodes).doc(code).get();
    final uid = snap.data()?[FsKeys.uid];
    return uid is String ? uid : null;
  }

  @override
  Future<List<ReferralEntry>> referredBy(String uid) async {
    final snap = await _db
        .collection(FsCol.referrals)
        .doc(uid)
        .collection(FsCol.referred)
        .orderBy(FsKeys.createdAt, descending: true)
        .limit(200)
        .get();
    return snap.docs.map(ReferralEntry.fromDoc).toList();
  }
}
