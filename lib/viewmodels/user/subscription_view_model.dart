import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/app_user.dart';
import '../../data/models/order_status.dart';
import '../../data/models/subscription_order.dart';
import '../../data/repositories/subscription_repository.dart';
import '../auth/session_view_model.dart';
import '../base_view_model.dart';
import 'proof_picker_mixin.dart';

class SubscriptionViewModel extends BaseViewModel with ProofPickerMixin {
  SubscriptionViewModel({required SubscriptionRepository repo, required SessionViewModel session})
    : _repo = repo,
      _session = session {
    final uid = session.uid;
    if (uid != null) {
      _orderSub = _repo
          .watchLatestOrder(uid)
          .listen(
            (o) {
              _latestOrder = o;
              _orderLoaded = true;
              notify();
            },
            onError: (Object e) {
              debugPrint('Latest order stream error: $e');
              _orderLoaded = true;
              notify();
            },
          );
    }
  }

  final SubscriptionRepository _repo;
  final SessionViewModel _session;
  StreamSubscription<SubscriptionOrder?>? _orderSub;

  SubscriptionOrder? _latestOrder;
  bool _orderLoaded = false;
  bool _resubmitting = false;

  SubscriptionOrder? get latestOrder => _latestOrder;
  bool get orderLoaded => _orderLoaded;
  AppUser? get user => _session.user;

  /// True when the form should be shown (not subscribed, nothing pending, and
  /// either no previous order or the user chose to resubmit after rejection).
  bool get canSubmit {
    final u = user;
    if (u == null || u.subscriptionActive || u.hasPendingSubscription || u.isBlocked) return false;
    return true;
  }

  bool get showRejected => canSubmit && !_resubmitting && _latestOrder?.status == OrderStatus.rejected;

  void startResubmit() {
    _resubmitting = true;
    notify();
  }

  Future<bool> submit({required String transactionId}) async {
    final bytes = proofBytes;
    final u = user;
    if (bytes == null) {
      setProofError(AppStrings.screenshotRequired);
      return false;
    }
    if (u == null || !_session.hasSettings) {
      setState(ViewState.error, error: AppStrings.settingsNotLoaded);
      return false;
    }
    final ok = await runAction(
      () => _repo.submit(
        user: u,
        expectedPrice: _session.settings!.subscriptionPrice,
        transactionId: transactionId,
        proofBytes: bytes,
      ),
    );
    if (ok) {
      _resubmitting = false;
      clearProof();
    }
    return ok;
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }
}
