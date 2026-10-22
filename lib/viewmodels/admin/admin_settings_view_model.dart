import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/faq_item.dart';
import '../../data/repositories/settings_repository.dart';
import '../auth/session_view_model.dart';
import '../base_view_model.dart';

/// App Settings (all tabs) + FAQ CRUD. Settings themselves are live from the
/// session's `settings/app` listener; this VM only writes.
class AdminSettingsViewModel extends BaseViewModel {
  AdminSettingsViewModel({required SettingsRepository repo, required SessionViewModel session})
    : _repo = repo,
      _session = session;

  final SettingsRepository _repo;
  final SessionViewModel _session;

  AppSettings? get settings => _session.settings;

  Future<bool> save(AppSettings next) => runAction(() => _repo.saveSettings(next));

  Future<bool> createDefaults() => runAction(_repo.createDefaults);

  // ---------------------------------------------------------------- FAQs
  List<FaqItem> _faqs = const [];
  bool _faqsLoading = false;
  String? _faqsError;
  bool _faqsLoaded = false;

  List<FaqItem> get faqs => _faqs;
  bool get faqsLoading => _faqsLoading;
  String? get faqsError => _faqsError;

  Future<void> loadFaqs({bool force = false}) async {
    if (_faqsLoading || (_faqsLoaded && !force)) return;
    _faqsLoading = true;
    _faqsError = null;
    notify();
    try {
      _faqs = await _repo.fetchFaqs(activeOnly: false);
      _faqsLoaded = true;
    } catch (e) {
      debugPrint('Load FAQs failed: $e');
      _faqsError = AppException.from(e).message;
    } finally {
      _faqsLoading = false;
      notify();
    }
  }

  Future<bool> saveFaq(FaqItem faq) async {
    final ok = await runAction(() => _repo.saveFaq(faq));
    if (ok) await loadFaqs(force: true);
    return ok;
  }

  Future<bool> deleteFaq(String id) async {
    final ok = await runAction(() => _repo.deleteFaq(id));
    if (ok) await loadFaqs(force: true);
    return ok;
  }
}
