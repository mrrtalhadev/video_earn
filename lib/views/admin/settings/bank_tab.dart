import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_settings.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'app_settings_screen.dart';

class BankTab extends StatefulWidget {
  const BankTab({super.key});

  @override
  State<BankTab> createState() => _BankTabState();
}

class _BankTabState extends State<BankTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late final BankDetails _b = context.read<AdminSettingsViewModel>().settings!.bank;
  late final _bankName = TextEditingController(text: _b.bankName);
  late final _title = TextEditingController(text: _b.accountTitle);
  late final _number = TextEditingController(text: _b.accountNumber);
  late final _iban = TextEditingController(text: _b.iban);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_bankName, _title, _number, _iban]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final next = vm.settings!.copyWith(
      bank: BankDetails(
        bankName: _bankName.text.trim(),
        accountTitle: _title.text.trim(),
        accountNumber: _number.text.trim(),
        iban: _iban.text.trim().toUpperCase(),
      ),
    );
    await saveSettingsWithFeedback(context, () => vm.save(next));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loading = context.select<AdminSettingsViewModel, bool>((v) => v.isLoading);
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          AppTextField(controller: _bankName, label: AppStrings.bankName, validator: Validators.required),
          AppTextField(controller: _title, label: AppStrings.accountTitle, validator: Validators.required),
          AppTextField(
            controller: _number,
            label: AppStrings.accountNumber,
            keyboardType: TextInputType.text,
            validator: Validators.required,
          ),
          AppTextField(controller: _iban, label: AppStrings.iban, textCapitalization: TextCapitalization.characters),
          SizedBox(height: 1.h),
          PrimaryButton(label: AppStrings.save, isLoading: loading, onPressed: _save),
        ],
      ),
    );
  }
}
