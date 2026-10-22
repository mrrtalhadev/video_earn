import 'package:flutter/foundation.dart';

import '../../data/repositories/proof_repository.dart';
import '../../data/repositories/promote_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../base_view_model.dart';

/// Shared admin-review helpers: lazily loaded payment screenshots, the
/// duplicate-transaction-ID check and per-item busy flags.
mixin ReviewSupport on BaseViewModel {
  ProofRepository get proofRepo;
  SubscriptionRepository get subscriptionRepo;
  PromoteRepository get promoteRepo;

  final Map<String, Uint8List?> _proofs = {};
  final Set<String> _proofLoading = {};
  final Map<String, int> _dupes = {};
  final Set<String> _dupeLoading = {};
  final Set<String> _busy = {};

  bool isBusy(String id) => _busy.contains(id);
  bool proofLoaded(String proofId) => _proofs.containsKey(proofId);
  bool isProofLoading(String proofId) => _proofLoading.contains(proofId);
  Uint8List? proof(String proofId) => _proofs[proofId];

  /// Number of OTHER orders (subscription + promote) using [transactionId],
  /// or null while unknown.
  int? duplicates(String transactionId) => _dupes[transactionId];

  Future<void> loadProof(String proofId) async {
    if (proofLoaded(proofId) || isProofLoading(proofId)) return;
    _proofLoading.add(proofId);
    notify();
    try {
      _proofs[proofId] = await proofRepo.load(proofId);
    } catch (e) {
      debugPrint('Proof load failed: $e');
      _proofs[proofId] = null;
    } finally {
      _proofLoading.remove(proofId);
      notify();
    }
  }

  Future<void> loadDuplicates(String transactionId) async {
    if (_dupes.containsKey(transactionId) || _dupeLoading.contains(transactionId)) return;
    _dupeLoading.add(transactionId);
    try {
      final counts = await Future.wait([
        subscriptionRepo.countSameTransactionId(transactionId),
        promoteRepo.countSameTransactionId(transactionId),
      ]);
      _dupes[transactionId] = (counts[0] + counts[1] - 1).clamp(0, 1 << 30);
      notify();
    } catch (e) {
      debugPrint('Duplicate check failed: $e');
    } finally {
      _dupeLoading.remove(transactionId);
    }
  }

  /// Runs a review action for one item with its own busy flag.
  @protected
  Future<bool> review(String id, Future<void> Function() action) async {
    _busy.add(id);
    notify();
    try {
      return await runAction(action, showLoading: false);
    } finally {
      _busy.remove(id);
      notify();
    }
  }
}
