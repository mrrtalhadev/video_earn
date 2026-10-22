import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import 'copyable_row.dart';
import 'notice_banner.dart';
import 'section_header.dart';

/// Admin bank account the user transfers to, with copy buttons.
class BankDetailsCard extends StatelessWidget {
  const BankDetailsCard({super.key, required this.bank});

  final BankDetails bank;

  @override
  Widget build(BuildContext context) {
    if (!bank.isConfigured) return NoticeBanner.warning(AppStrings.bankNotConfigured);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  bank.bankName.isEmpty ? AppStrings.bankDetails : bank.bankName,
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          CopyableRow(label: AppStrings.accountTitle, value: bank.accountTitle),
          CopyableRow(label: AppStrings.accountNumber, value: bank.accountNumber),
          if (bank.iban.isNotEmpty) CopyableRow(label: AppStrings.iban, value: bank.iban),
        ],
      ),
    );
  }
}
