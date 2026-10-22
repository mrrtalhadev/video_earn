import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'page_result.dart';

abstract class UserRepository {
  /// Live user doc; emits null while the doc does not exist.
  Stream<AppUser?> watchUser(String uid);
  Future<void> updateProfile({required String uid, required String name, required String phone, String? photoUrl});
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<AppUser?> watchUser(String uid) =>
      _db.collection(FsCol.users).doc(uid).snapshots().map((s) => s.exists ? AppUser.fromDoc(s) : null);

  @override
  Future<void> updateProfile({required String uid, required String name, required String phone, String? photoUrl}) {
    final trimmed = name.trim();
    final photo = photoUrl?.trim();
    return _db.collection(FsCol.users).doc(uid).update({
      FsKeys.name: trimmed,
      FsKeys.nameLower: trimmed.toLowerCase(),
      FsKeys.phone: phone,
      FsKeys.photoUrl: (photo == null || photo.isEmpty) ? null : photo,
    }).withWriteTimeout();
  }
}
