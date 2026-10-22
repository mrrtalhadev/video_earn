import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';

abstract final class ConfirmDialog {
  /// Returns true when the user confirms.
  static Future<bool> show(
    BuildContext context, {
    String title = AppStrings.areYouSure,
    required String message,
    String confirmLabel = AppStrings.confirm,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15.6.sp),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: destructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15.6.sp,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Asks for a text value (e.g. a rejection reason). Returns null if cancelled.
  static Future<String?> input(
    BuildContext context, {
    required String title,
    required String label,
    String confirmLabel = AppStrings.confirm,
    bool required = true,
    bool destructive = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _InputDialog(
        title: title,
        label: label,
        confirmLabel: confirmLabel,
        isRequired: required,
        destructive: destructive,
      ),
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.isRequired,
    required this.destructive,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final bool isRequired;
  final bool destructive;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          maxLength: AppConstants.maxReasonLength,
          decoration: InputDecoration(labelText: widget.label),
          validator: (v) {
            if (widget.isRequired && Validators.required(v) != null) {
              return AppStrings.rejectReasonRequired;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.cancel,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15.6.sp),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: TextStyle(
              color: widget.destructive ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15.6.sp,
            ),
          ),
        ),
      ],
    );
  }
}
