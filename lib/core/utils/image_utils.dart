import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../errors/app_exception.dart';

abstract final class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Lets the user pick a screenshot from the gallery. Returns null if cancelled.
  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      throw const AppException(AppStrings.errorImagePick);
    }
  }

  /// Resizes (max width 1080) and re-encodes as JPEG, lowering quality and
  /// width until the result is below [AppConstants.proofTargetBytes].
  static Future<Uint8List> compressProof(XFile file) async {
    final Uint8List original;
    try {
      original = await file.readAsBytes();
    } catch (_) {
      throw const AppException(AppStrings.errorImagePick);
    }

    const widths = [AppConstants.proofMaxWidth, 900, 720, 600];
    const qualities = [AppConstants.proofStartQuality, 50, 40, 30];
    for (final width in widths) {
      for (final quality in qualities) {
        final out = await FlutterImageCompress.compressWithList(
          original,
          minWidth: width,
          minHeight: width,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (out.isNotEmpty && out.lengthInBytes < AppConstants.proofTargetBytes) return out;
      }
    }
    throw const AppException(AppStrings.errorImageTooLarge);
  }
}
