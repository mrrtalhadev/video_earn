import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';

enum SessionStatus { unknown, signedOut, user, admin, maintenance, updateRequired, incomplete }

/// App-wide session: who is signed in, their role, their live user doc and
/// the live `settings/app`. Drives the router's role guard.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel({required AuthRepository auth, required UserRepository users, required SettingsRepository settings})
    : _auth = auth,
      _users = users,
      _settingsRepo = settings {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _auth;
  final UserRepository _users;
  final SettingsRepository _settingsRepo;

  late final StreamSubscription<User?> _authSub;
  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<AppSettings?>? _settingsSub;

  SessionStatus _status = SessionStatus.unknown;
  bool _splashDone = false;
  bool _signupInProgress = false;
  bool _isAdmin = false;
  bool _userLoaded = false;
  bool _settingsLoaded = false;
  String? _uid;
  AppUser? _user;
  AppSettings? _settings;
  String? _notice;
  String? _loadError;
  String? _statusUpdate;
  bool _disposed = false;

  SessionStatus get status => _status;
  bool get splashDone => _splashDone;
  String? get uid => _uid;
  AppUser? get user => _user;

  /// Null until the admin creates default settings.
  AppSettings? get settings => _settings;
  bool get hasSettings => _settings != null;

  /// Settings with safe defaults for display when the doc is missing.
  AppSettings get settingsOrDefault => _settings ?? const AppSettings();

  bool get isAdmin => _isAdmin;

  /// One-shot message for the login screen (e.g. "account blocked").
  String? get notice => _notice;
  String? get loadError => _loadError;

  /// Pending "status updated" message (e.g. subscription approved).
  bool get hasStatusUpdate => _statusUpdate != null;

  void markSplashDone() {
    if (_splashDone) return;
    _splashDone = true;
    _notify();
  }

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    _notify();
  }

  /// While a signup is running, the new auth user has no profile doc yet.
  /// Session resolution waits until [endSignup] so the signup screen stays
  /// visible (with its error) if the profile batch fails.
  void beginSignup() => _signupInProgress = true;

  void endSignup() {
    _signupInProgress = false;
    _onAuthChanged(_auth.currentUser);
  }

  Future<void> retry() async => _onAuthChanged(_auth.currentUser);

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  Future<void> _onAuthChanged(User? fbUser) async {
    if (_signupInProgress) return;
    await _cancelDocSubs();
    _user = null;
    _settings = null;
    _isAdmin = false;
    _userLoaded = false;
    _settingsLoaded = false;
    _loadError = null;

    if (fbUser == null) {
      _uid = null;
      _status = SessionStatus.signedOut;
      _notify();
      return;
    }

    _uid = fbUser.uid;
    _status = SessionStatus.unknown;
    _notify();

    try {
      _isAdmin = await _auth.isAdmin(fbUser.uid);
    } catch (e) {
      debugPrint('Role check failed: $e');
      _loadError = AppException.from(e).message;
      _notify();
      return;
    }
    if (_uid != fbUser.uid) return; // signed out / switched meanwhile

    _settingsSub = _settingsRepo.watchSettings().listen((s) {
      _settings = s;
      _settingsLoaded = true;
      _resolve();
    }, onError: _onStreamError);

    if (_isAdmin) {
      _userLoaded = true;
    } else {
      _userSub = _users.watchUser(fbUser.uid).listen(_onUserDoc, onError: _onStreamError);
    }
  }

  void _onUserDoc(AppUser? doc) {
    _userLoaded = true;
    final previous = _user;
    _user = doc;
    if (previous != null && doc != null && previous.uid == doc.uid) _detectStatusUpdate(previous, doc);
    if (doc != null && doc.isBlocked) {
      _notice = AppStrings.blockedMessage;
      signOut();
      return;
    }
    _resolve();
  }

  /// Admin decisions arrive through the live user doc (no push
  /// notifications on the free plan); turn them into a one-shot message.
  void _detectStatusUpdate(AppUser before, AppUser after) {
    if (!before.subscriptionActive && after.subscriptionActive) {
      _statusUpdate = AppStrings.subscriptionActivatedBanner;
    } else if (before.hasPendingSubscription && !after.hasPendingSubscription && !after.subscriptionActive) {
      _statusUpdate = AppStrings.subscriptionRejectedBanner;
    } else if (after.totalReferralEarned > before.totalReferralEarned) {
      _statusUpdate = AppStrings.referralBonusBanner(
        Formatters.pkr(after.totalReferralEarned - before.totalReferralEarned),
      );
    } else if (after.pendingWithdraw < before.pendingWithdraw) {
      _statusUpdate = AppStrings.withdrawProcessedBanner;
    }
  }

  /// Returns and clears the pending status message.
  String? takeStatusUpdate() {
    final m = _statusUpdate;
    _statusUpdate = null;
    return m;
  }

  void _onStreamError(Object e) {
    debugPrint('Session stream error: $e');
    _loadError = AppException.from(e).message;
    _notify();
  }

  void _resolve() {
    if (!_userLoaded || !_settingsLoaded) return;
    final next = _computeStatus();
    if (next != _status) _status = next;
    _notify();
  }

  SessionStatus _computeStatus() {
    if (_isAdmin) return SessionStatus.admin;
    if (_user == null) return SessionStatus.incomplete;
    final s = _settings;
    if (s != null && s.maintenanceMode) return SessionStatus.maintenance;
    if (s != null && s.requiresUpdate) return SessionStatus.updateRequired;
    return SessionStatus.user;
  }

  Future<void> _cancelDocSubs() async {
    await _userSub?.cancel();
    await _settingsSub?.cancel();
    _userSub = null;
    _settingsSub = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub.cancel();
    _cancelDocSubs();
    super.dispose();
  }
}
