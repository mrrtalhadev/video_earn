import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/snackbars.dart';

/// `label / value` row with a copy-to-clipboard button.
class CopyableRow extends StatelessWidget {
  const CopyableRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                SizedBox(height: 0.2.h),
                SelectableText(hasValue ? value : AppStrings.notSet, style: AppTextStyles.subtitle),
              ],
            ),
          ),
          if (hasValue)
            IconButton(
              tooltip: AppStrings.copy,
              icon: Icon(Icons.copy_rounded, color: AppColors.primary, size: 5.5.w),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) AppSnackbars.info(context, AppStrings.copied);
              },
            ),
        ],
      ),
    );
  }
}
