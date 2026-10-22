import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'zoomable_image_viewer.dart';

/// Tap-to-pick screenshot field showing a preview of the compressed image.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.label,
    required this.bytes,
    required this.onPick,
    this.isProcessing = false,
    this.errorText,
  });

  final String label;
  final Uint8List? bytes;
  final VoidCallback? onPick;
  final bool isProcessing;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null ? AppColors.error : AppColors.divider;
    return Padding(
      padding: EdgeInsets.only(bottom: 1.8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          SizedBox(height: 0.8.h),
          InkWell(
            onTap: isProcessing ? null : onPick,
            borderRadius: BorderRadius.circular(3.w),
            child: Container(
              height: bytes == null ? 16.h : 28.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(3.w),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: isProcessing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: 1.h),
                        Text(AppStrings.compressingImage, style: AppTextStyles.caption),
                      ],
                    )
                  : bytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 10.w, color: AppColors.primary),
                        SizedBox(height: 1.h),
                        Text(AppStrings.pickScreenshot, style: AppTextStyles.bodySecondary),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => ZoomableImageViewer.open(context, bytes!),
                          child: Image.memory(bytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 2.w,
                          bottom: 1.h,
                          child: FilledButton.tonalIcon(
                            onPressed: onPick,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text(AppStrings.changeScreenshot),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: EdgeInsets.only(top: 0.6.h, left: 3.w),
              child: Text(errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}
