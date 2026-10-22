import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'page_result.dart';

enum UserFilter { all, subscribed, notSubscribed, blocked }

abstract class AdminUserRepository {
  /// Paginated users. With a [search] term, does a prefix search on email
  /// (contains '@'), phone (starts with a digit or '+') or lower-case name,
  /// and applies [filter] to the page client-side.
  Future<PageResult<AppUser>> fetchUsers({UserFilter filter = UserFilter.all, String search = '', JsonDoc? startAfter});

  Stream<AppUser?> watchUser(String uid);
  Future<void> setBlocked(String uid, bool blocked);
}

class FirestoreAdminUserRepository implements AdminUserRepository {
  FirestoreAdminUserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection(FsCol.users);

  @override
  Future<PageResult<AppUser>> fetchUsers({
    UserFilter filter = UserFilter.all,
    String search = '',
    JsonDoc? startAfter,
  }) async {
    final term = search.trim();
    if (term.isEmpty) {
      final JsonQuery q = switch (filter) {
        UserFilter.all => _users,
        UserFilter.subscribed => _users.where(FsKeys.subscriptionActive, isEqualTo: true),
        UserFilter.notSubscribed => _users.where(FsKeys.subscriptionActive, isEqualTo: false),
        UserFilter.blocked => _users.where(FsKeys.isBlocked, isEqualTo: true),
      };
      return fetchPage(q.orderBy(FsKeys.createdAt, descending: true), AppUser.fromDoc, startAfter: startAfter);
    }

    final String field;
    final String value;
    if (term.contains('@')) {
      field = FsKeys.email;
      value = term.toLowerCase();
    } else if (RegExp(r'^[+\d]').hasMatch(term)) {
      field = FsKeys.phone;
      value = term.replaceAll(' ', '');
    } else {
      field = FsKeys.nameLower;
      value = term.toLowerCase();
    }
    final q = _users.where(field, isGreaterThanOrEqualTo: value).where(field, isLessThan: '$value\uf8ff').orderBy(field);
    final page = await fetchPage(q, AppUser.fromDoc, startAfter: startAfter);
    return PageResult(
      items: page.items.where((u) => _matches(u, filter)).toList(),
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  bool _matches(AppUser u, UserFilter f) => switch (f) {
    UserFilter.all => true,
    UserFilter.subscribed => u.subscriptionActive,
    UserFilter.notSubscribed => !u.subscriptionActive,
    UserFilter.blocked => u.isBlocked,
  };

  @override
  Stream<AppUser?> watchUser(String uid) =>
      _users.doc(uid).snapshots().map((s) => s.exists ? AppUser.fromDoc(s) : null);

  @override
  Future<void> setBlocked(String uid, bool blocked) =>
      _users.doc(uid).update({FsKeys.isBlocked: blocked}).withWriteTimeout();
}
