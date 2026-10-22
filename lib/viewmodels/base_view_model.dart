import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';

enum ViewState { idle, loading, success, error }

/// Base for every ViewModel: exposes [state] and [errorMessage], and guards
/// notifications after dispose.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isDisposed => _disposed;

  @protected
  void setState(ViewState value, {String? error}) {
    _state = value;
    _errorMessage = value == ViewState.error ? error : null;
    notify();
  }

  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  /// Runs [action] with loading/success/error bookkeeping. Returns the result,
  /// or null on failure (the friendly message is in [errorMessage]).
  @protected
  Future<T?> guard<T>(Future<T> Function() action, {bool showLoading = true}) async {
    if (showLoading) setState(ViewState.loading);
    try {
      final result = await action();
      setState(ViewState.success);
      return result;
    } catch (e, st) {
      debugPrint('$runtimeType error: $e\n$st');
      setState(ViewState.error, error: AppException.from(e).message);
      return null;
    }
  }

  /// Like [guard] for actions without a result: returns true on success.
  @protected
  Future<bool> runAction(Future<void> Function() action, {bool showLoading = true}) async {
    if (showLoading) setState(ViewState.loading);
    try {
      await action();
      setState(ViewState.success);
      return true;
    } catch (e, st) {
      debugPrint('$runtimeType error: $e\n$st');
      setState(ViewState.error, error: AppException.from(e).message);
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
