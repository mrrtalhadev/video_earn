import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import 'app_settings_screen.dart';

class SystemTab extends StatefulWidget {
  const SystemTab({super.key});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late bool _maintenance = context.read<AdminSettingsViewModel>().settings!.maintenanceMode;
  late final _version = TextEditingController(text: context.read<AdminSettingsViewModel>().settings!.minAppVersion);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _version.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final next = vm.settings!.copyWith(maintenanceMode: _maintenance, minAppVersion: _version.text.trim());
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
          AppCard(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 2.w),
              value: _maintenance,
              onChanged: (v) => setState(() => _maintenance = v),
              title: const Text(AppStrings.maintenanceMode),
              subtitle: const Text(AppStrings.maintenanceModeHint),
            ),
          ),
          SizedBox(height: 2.h),
          AppTextField(controller: _version, label: AppStrings.minAppVersion, validator: Validators.version),
          SizedBox(height: 1.h),
          PrimaryButton(label: AppStrings.save, isLoading: loading, onPressed: _save),
          SizedBox(height: 3.h),
          NoticeBanner.warning(AppStrings.adminSecurityNote),
        ],
      ),
    );
  }
}
