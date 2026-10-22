import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/validators.dart';
import 'app_text_field.dart';

/// Whole-number input (money is always integer PKR).
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.validator = Validators.positiveInt,
    this.readOnly = false,
    this.prefixIcon,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final bool readOnly;
  final IconData? prefixIcon;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      readOnly: readOnly,
      prefixIcon: prefixIcon,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
      validator: validator,
    );
  }
}
