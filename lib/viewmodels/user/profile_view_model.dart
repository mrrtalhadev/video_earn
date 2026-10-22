import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/models/faq_item.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../base_view_model.dart';

class EditProfileViewModel extends BaseViewModel {
  EditProfileViewModel({required UserRepository repo, required String uid}) : _repo = repo, _uid = uid;

  final UserRepository _repo;
  final String _uid;

  Future<bool> save({required String name, required String phone, String? photoUrl}) => runAction(
    () => _repo.updateProfile(uid: _uid, name: name, phone: Validators.normalizePhone(phone), photoUrl: photoUrl),
  );
}

class FaqViewModel extends BaseViewModel {
  FaqViewModel(this._repo) {
    load();
  }

  final SettingsRepository _repo;
  List<FaqItem> _faqs = const [];
  bool _loaded = false;

  List<FaqItem> get faqs => _faqs;
  bool get loaded => _loaded;

  Future<void> load() async {
    setState(ViewState.loading);
    try {
      _faqs = await _repo.fetchFaqs();
      _loaded = true;
      setState(ViewState.success);
    } catch (e) {
      debugPrint('FAQ load failed: $e');
      setState(ViewState.error, error: AppException.from(e).message);
    }
  }
}
