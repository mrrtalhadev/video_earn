import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Full-screen pinch-to-zoom viewer for in-memory images (payment proofs).
class ZoomableImageViewer extends StatelessWidget {
  const ZoomableImageViewer({super.key, required this.bytes});

  final Uint8List bytes;

  static Future<void> open(BuildContext context, Uint8List bytes) {
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => ZoomableImageViewer(bytes: bytes)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          tooltip: AppStrings.close,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
      ),
    );
  }
}
