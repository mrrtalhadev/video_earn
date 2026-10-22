import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/image_utils.dart';
import '../base_view_model.dart';

/// Pick + compress a payment screenshot (shared by Subscription and Promote).
mixin ProofPickerMixin on BaseViewModel {
  Uint8List? _proofBytes;
  bool _compressing = false;
  String? _proofError;

  Uint8List? get proofBytes => _proofBytes;
  bool get compressing => _compressing;
  String? get proofError => _proofError;

  Future<void> pickProof() async {
    _proofError = null;
    try {
      final file = await ImageUtils.pickFromGallery();
      if (file == null) return;
      _compressing = true;
      notify();
      _proofBytes = await ImageUtils.compressProof(file);
    } catch (e) {
      debugPrint('Proof pick failed: $e');
      _proofError = AppException.from(e).message;
    } finally {
      _compressing = false;
      notify();
    }
  }

  void setProofError(String? message) {
    _proofError = message;
    notify();
  }

  void clearProof() {
    _proofBytes = null;
    _proofError = null;
    notify();
  }
}
