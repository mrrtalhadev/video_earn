import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final fg = outlined ? AppColors.primary : AppColors.white;
    final child = isLoading
        ? SizedBox(
            height: 5.w,
            width: 5.w,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 5.w), SizedBox(width: 2.w)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: enabled ? onPressed : null, child: child)
          : ElevatedButton(onPressed: enabled ? onPressed : null, child: child),
    );
  }
}
