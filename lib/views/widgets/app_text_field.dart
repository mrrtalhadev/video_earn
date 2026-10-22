import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.8.h),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.maxLines > 1 ? TextInputAction.newline : widget.textInputAction,
        obscureText: widget.isPassword && _obscured,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        style: AppTextStyles.body.copyWith(color: widget.readOnly ? AppColors.textSecondary : AppColors.textPrimary),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          errorMaxLines: 3,
          alignLabelWithHint: widget.maxLines > 1,
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 5.5.w),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                    size: 5.5.w,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : widget.suffix,
        ),
      ),
    );
  }
}
