import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/app_user.dart';
import '../../data/models/promote_order.dart';
import '../../data/models/subscription_order.dart';
import '../../data/models/withdraw_request.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../../data/repositories/page_result.dart';
import '../../data/repositories/promote_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/withdraw_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';

class AdminUsersViewModel extends BaseViewModel {
  AdminUsersViewModel(this._repo) {
    _rebuild();
  }

  final AdminUserRepository _repo;
  UserFilter _filter = UserFilter.all;
  String _search = '';
  Timer? _debounce;
  late PagedList<AppUser> users;

  UserFilter get filter => _filter;

  void setFilter(UserFilter f) {
    if (f == _filter) return;
    _filter = f;
    _rebuild();
  }

  void setSearch(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (term.trim() == _search) return;
      _search = term.trim();
      _rebuild();
    });
  }

  void _rebuild() {
    final f = _filter, s = _search;
    users = PagedList<AppUser>((c) => _repo.fetchUsers(filter: f, search: s, startAfter: c), notify);
    notify();
    users.refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Live user doc + deposit / withdraw / promote history + block toggle.
class UserDetailViewModel extends BaseViewModel {
  UserDetailViewModel({
    required this.uid,
    required AdminUserRepository users,
    required SubscriptionRepository subscriptions,
    required WithdrawRepository withdrawals,
    required PromoteRepository promote,
  }) : _users = users,
       _subscriptions = subscriptions,
       _withdrawals = withdrawals,
       _promote = promote {
    _sub = _users
        .watchUser(uid)
        .listen(
          (u) {
            _user = u;
            _userLoaded = true;
            notify();
          },
          onError: (Object e) {
            _userError = AppException.from(e).message;
            notify();
          },
        );
    loadHistory();
  }

  final String uid;
  final AdminUserRepository _users;
  final SubscriptionRepository _subscriptions;
  final WithdrawRepository _withdrawals;
  final PromoteRepository _promote;
  late final StreamSubscription<AppUser?> _sub;

  AppUser? _user;
  bool _userLoaded = false;
  String? _userError;
  List<SubscriptionOrder> _deposits = const [];
  List<WithdrawRequest> _withdraws = const [];
  List<PromoteOrder> _promotes = const [];
  bool _historyLoading = false;
  String? _historyError;

  AppUser? get user => _user;
  bool get userLoaded => _userLoaded;
  String? get userError => _userError;
  List<SubscriptionOrder> get deposits => _deposits;
  List<WithdrawRequest> get withdraws => _withdraws;
  List<PromoteOrder> get promotes => _promotes;
  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;

  Future<void> loadHistory() async {
    _historyLoading = true;
    _historyError = null;
    notify();
    try {
      final r = await Future.wait([
        _subscriptions.ordersForUser(uid),
        _withdrawals.pageForUser(uid),
        _promote.pageForUser(uid),
      ]);
      _deposits = r[0] as List<SubscriptionOrder>;
      _withdraws = (r[1] as PageResult<WithdrawRequest>).items;
      _promotes = (r[2] as PageResult<PromoteOrder>).items;
    } catch (e) {
      debugPrint('User history failed: $e');
      _historyError = AppException.from(e).message;
    } finally {
      _historyLoading = false;
      notify();
    }
  }

  Future<bool> setBlocked(bool blocked) => runAction(() => _users.setBlocked(uid, blocked));

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
