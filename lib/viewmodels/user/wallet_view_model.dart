import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../base_view_model.dart';

/// Recent ledger rows for the Wallet tab. Balances come live from the
/// session's user listener, so only the ledger is fetched here.
class WalletViewModel extends BaseViewModel {
  WalletViewModel({required WalletRepository repo, required String uid}) : _repo = repo, _uid = uid {
    load();
  }

  final WalletRepository _repo;
  final String _uid;

  List<WalletTransaction> _recent = const [];
  bool _loaded = false;

  List<WalletTransaction> get recent => _recent;
  bool get loaded => _loaded;

  Future<void> load() async {
    setState(ViewState.loading);
    try {
      _recent = await _repo.recent(_uid);
      _loaded = true;
      setState(ViewState.success);
    } catch (e) {
      debugPrint('Wallet load failed: $e');
      setState(ViewState.error, error: AppException.from(e).message);
    }
  }
}
