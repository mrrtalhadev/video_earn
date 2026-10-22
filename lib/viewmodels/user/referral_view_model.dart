import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/referral_entry.dart';
import '../../data/repositories/referral_repository.dart';
import '../base_view_model.dart';

class ReferralViewModel extends BaseViewModel {
  ReferralViewModel({required ReferralRepository repo, required String uid}) : _repo = repo, _uid = uid {
    load();
  }

  final ReferralRepository _repo;
  final String _uid;

  List<ReferralEntry> _entries = const [];
  bool _loaded = false;

  List<ReferralEntry> get entries => _entries;
  bool get loaded => _loaded;
  int get totalReferred => _entries.length;
  int get subscribedCount => _entries.where((e) => e.bonusPaid).length;

  Future<void> load() async {
    setState(ViewState.loading);
    try {
      _entries = await _repo.referredBy(_uid);
      _loaded = true;
      setState(ViewState.success);
    } catch (e) {
      debugPrint('Referral load failed: $e');
      setState(ViewState.error, error: AppException.from(e).message);
    }
  }
}
