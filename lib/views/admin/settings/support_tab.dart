import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_settings.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import 'app_settings_screen.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late final AppSettings _s = context.read<AdminSettingsViewModel>().settings!;
  late final _whatsapp = TextEditingController(text: _s.supportWhatsapp);
  late final _email = TextEditingController(text: _s.supportEmail);
  late final _cPhone = TextEditingController(text: _s.contactUs.phone);
  late final _cEmail = TextEditingController(text: _s.contactUs.email);
  late final _cWhatsapp = TextEditingController(text: _s.contactUs.whatsapp);
  late final _cAddress = TextEditingController(text: _s.contactUs.address);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_whatsapp, _email, _cPhone, _cEmail, _cWhatsapp, _cAddress]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optionalEmail(String? v) => (v == null || v.trim().isEmpty) ? null : Validators.email(v);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final next = vm.settings!.copyWith(
      supportWhatsapp: _whatsapp.text.trim(),
      supportEmail: _email.text.trim(),
      contactUs: ContactInfo(
        phone: _cPhone.text.trim(),
        email: _cEmail.text.trim(),
        whatsapp: _cWhatsapp.text.trim(),
        address: _cAddress.text.trim(),
      ),
    );
    await saveSettingsWithFeedback(context, () => vm.save(next));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loading = context.select<AdminSettingsViewModel, bool>((v) => v.isLoading);
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[\d+]'))];
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          AppTextField(
            controller: _whatsapp,
            label: AppStrings.supportWhatsapp,
            keyboardType: TextInputType.phone,
            inputFormatters: digits,
          ),
          AppTextField(
            controller: _email,
            label: AppStrings.supportEmail,
            keyboardType: TextInputType.emailAddress,
            validator: _optionalEmail,
          ),
          const SectionHeader(title: AppStrings.contactUs),
          AppTextField(
            controller: _cPhone,
            label: AppStrings.contactPhoneLabel,
            keyboardType: TextInputType.phone,
            inputFormatters: digits,
          ),
          AppTextField(
            controller: _cEmail,
            label: AppStrings.contactEmailLabel,
            keyboardType: TextInputType.emailAddress,
            validator: _optionalEmail,
          ),
          AppTextField(
            controller: _cWhatsapp,
            label: AppStrings.contactWhatsappLabel,
            keyboardType: TextInputType.phone,
            inputFormatters: digits,
          ),
          AppTextField(controller: _cAddress, label: AppStrings.address, maxLines: 3),
          SizedBox(height: 1.h),
          PrimaryButton(label: AppStrings.save, isLoading: loading, onPressed: _save),
        ],
      ),
    );
  }
}
