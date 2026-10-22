import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/youtube_utils.dart';
import '../../data/models/promote_package.dart';
import '../../data/repositories/promote_repository.dart';
import '../base_view_model.dart';
import 'proof_picker_mixin.dart';

class PromoteViewModel extends BaseViewModel with ProofPickerMixin {
  PromoteViewModel({required PromoteRepository repo, required String uid}) : _repo = repo, _uid = uid {
    loadPackages();
  }

  final PromoteRepository _repo;
  final String _uid;

  List<PromotePackage> _packages = const [];
  bool _packagesLoading = false;
  String? _packagesError;
  PromotePackage? _selected;
  String? _packageError;

  List<PromotePackage> get packages => _packages;
  bool get packagesLoading => _packagesLoading;
  String? get packagesError => _packagesError;
  PromotePackage? get selected => _selected;
  String? get packageError => _packageError;

  Future<void> loadPackages() async {
    _packagesLoading = true;
    _packagesError = null;
    notify();
    try {
      _packages = await _repo.fetchPackages();
      if (_selected != null && !_packages.any((p) => p.id == _selected!.id)) _selected = null;
    } catch (e) {
      debugPrint('Load packages failed: $e');
      _packagesError = AppException.from(e).message;
    } finally {
      _packagesLoading = false;
      notify();
    }
  }

  void select(PromotePackage p) {
    _selected = p;
    _packageError = null;
    notify();
  }

  Future<bool> submit({
    required String videoUrl,
    required String title,
    required String description,
    required String transactionId,
  }) async {
    final pkg = _selected;
    final bytes = proofBytes;
    if (pkg == null) {
      _packageError = AppStrings.packageRequired;
      notify();
    }
    if (bytes == null) setProofError(AppStrings.screenshotRequired);
    final videoId = YoutubeUtils.extractVideoId(videoUrl);
    if (pkg == null || bytes == null || videoId == null) return false;

    final ok = await runAction(
      () => _repo.submitOrder(
        uid: _uid,
        package: pkg,
        videoUrl: videoUrl,
        videoId: videoId,
        title: title,
        description: description,
        transactionId: transactionId,
        proofBytes: bytes,
      ),
    );
    if (ok) {
      _selected = null;
      clearProof();
    } else if (errorMessage == AppStrings.priceChanged) {
      await loadPackages();
    }
    return ok;
  }
}
