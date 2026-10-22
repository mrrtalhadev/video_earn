import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_settings.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/number_field.dart';
import '../../widgets/primary_button.dart';
import 'app_settings_screen.dart';

class PricingTab extends StatefulWidget {
  const PricingTab({super.key});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late final AppSettings _initial = context.read<AdminSettingsViewModel>().settings!;
  late final _price = TextEditingController(text: '${_initial.subscriptionPrice}');
  late final _reward = TextEditingController(text: '${_initial.videoReward}');
  late final _bonus = TextEditingController(text: '${_initial.referralBonus}');
  late final _minWithdraw = TextEditingController(text: '${_initial.minWithdraw}');
  late final _cooldown = TextEditingController(text: '${_initial.withdrawCooldownDays}');
  late final _watchPct = TextEditingController(text: '${_initial.minWatchPercent}');
  late final _maxMinutes = TextEditingController(text: '${_initial.maxVideoMinutes}');

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_price, _reward, _bonus, _minWithdraw, _cooldown, _watchPct, _maxMinutes]) {
      c.dispose();
    }
    super.dispose();
  }

  int _v(TextEditingController c) => int.parse(c.text.trim());

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final current = vm.settings!;
    final next = current.copyWith(
      subscriptionPrice: _v(_price),
      videoReward: _v(_reward),
      referralBonus: _v(_bonus),
      minWithdraw: _v(_minWithdraw),
      withdrawCooldownDays: _v(_cooldown),
      minWatchPercent: _v(_watchPct),
      maxVideoMinutes: _v(_maxMinutes),
    );
    final moneyChanged =
        next.subscriptionPrice != current.subscriptionPrice ||
        next.videoReward != current.videoReward ||
        next.referralBonus != current.referralBonus;
    if (moneyChanged) {
      final ok = await ConfirmDialog.show(
        context,
        title: AppStrings.confirmPriceChangeTitle,
        message: AppStrings.confirmPriceChange,
      );
      if (!ok || !mounted) return;
    }
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
          NumberField(controller: _price, label: AppStrings.subscriptionPrice),
          NumberField(controller: _reward, label: AppStrings.videoReward),
          NumberField(controller: _bonus, label: AppStrings.referralBonus),
          NumberField(controller: _minWithdraw, label: AppStrings.minWithdraw),
          NumberField(controller: _cooldown, label: AppStrings.withdrawCooldownDays),
          NumberField(controller: _watchPct, label: AppStrings.minWatchPercent, validator: Validators.percent),
          NumberField(controller: _maxMinutes, label: AppStrings.maxVideoMinutes),
          SizedBox(height: 1.h),
          PrimaryButton(label: AppStrings.save, isLoading: loading, onPressed: _save),
        ],
      ),
    );
  }
}
