import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/referral_entry.dart';
import 'page_result.dart';
import 'referral_repository.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<bool> isAdmin(String uid);
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
    required ReferralRepository referrals,
  }) : _auth = auth,
       _db = db,
       _referrals = referrals;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final ReferralRepository _referrals;
  final Random _random = Random.secure();

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<bool> isAdmin(String uid) async {
    final snap = await _db.collection(FsCol.admins).doc(uid).get();
    return snap.exists;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// 1. validate referral code → 2. create auth user → 3. one batch creating
  /// the user doc, a unique referral code and (if referred) the referral
  /// entry. If the batch cannot be committed the auth user is deleted, so no
  /// half-created accounts remain.
  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    final usedCode = referralCode?.trim().toUpperCase();
    String? referrerUid;
    if (usedCode != null && usedCode.isNotEmpty) {
      referrerUid = await _referrals.ownerOfCode(usedCode);
      if (referrerUid == null) throw const AppException(AppStrings.referralCodeInvalid);
    }

    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    try {
      await _createProfile(
        uid: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        phone: phone,
        referrerUid: referrerUid,
        usedCode: referrerUid == null ? null : usedCode,
      );
    } catch (e) {
      debugPrint('Signup batch failed, removing auth user: $e');
      try {
        await user.delete();
      } catch (deleteError) {
        debugPrint('Could not delete auth user: $deleteError');
        await _auth.signOut();
      }
      if (e is AppException) rethrow;
      throw const AppException(AppStrings.signupFailedCleanup);
    }
  }

  Future<void> _createProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String? referrerUid,
    required String? usedCode,
  }) async {
    for (var attempt = 0; attempt < AppConstants.referralCodeRetries; attempt++) {
      final code = _generateCode();
      // Cheap pre-check; the create-only rule is the real uniqueness guarantee.
      if (await _referrals.ownerOfCode(code) != null) continue;

      final batch = _db.batch();
      batch.set(
        _db.collection(FsCol.users).doc(uid),
        AppUser.createMap(
          name: name,
          email: email,
          phone: phone,
          referralCode: code,
          referredBy: referrerUid,
          referredByCode: usedCode,
        ),
      );
      batch.set(_db.collection(FsCol.referralCodes).doc(code), {FsKeys.uid: uid});
      if (referrerUid != null) {
        batch.set(_db.collection(FsCol.referrals).doc(referrerUid).collection(FsCol.referred).doc(uid), {
          FsKeys.refereeName: name,
          FsKeys.status: ReferralEntry.statusPending,
          FsKeys.bonus: 0,
          FsKeys.createdAt: FieldValue.serverTimestamp(),
        });
      }
      try {
        await batch.commit().withWriteTimeout();
        return;
      } on FirebaseException catch (e) {
        // A code taken between the pre-check and the commit surfaces as
        // permission-denied (create on an existing doc). Retry with a new code.
        if (e.code != 'permission-denied' || attempt == AppConstants.referralCodeRetries - 1) {
          rethrow;
        }
      }
    }
    throw const AppException(AppStrings.errorReferralCode);
  }

  String _generateCode() {
    const alphabet = AppConstants.referralCodeAlphabet;
    return List.generate(AppConstants.referralCodeLength, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() => _auth.signOut();
}
