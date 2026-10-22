import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// App-wide online/offline flag. Submit buttons for money actions are
/// disabled while offline so writes are never queued silently.
class ConnectivityViewModel extends ChangeNotifier {
  ConnectivityViewModel({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity!.onConnectivityChanged.listen(_update);
    _connectivity.checkConnectivity().then(_update).catchError((Object e) {
      debugPrint('Connectivity check failed: $e');
    });
  }

  /// Fixed state without platform plugins (widget tests).
  @visibleForTesting
  ConnectivityViewModel.fixed({bool online = true}) : _connectivity = null, _isOnline = online;

  final Connectivity? _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
