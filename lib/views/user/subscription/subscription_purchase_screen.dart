import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/subscription_order.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/connectivity_view_model.dart';
import '../../../viewmodels/user/subscription_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bank_details_card.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/success_dialog.dart';

/// Subscription purchase (also the "Deposit" screen).
class SubscriptionPurchaseScreen extends StatelessWidget {
  const SubscriptionPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          SubscriptionViewModel(repo: ctx.read<SubscriptionRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatelessWidget {
  const _SubscriptionView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionViewModel>();
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);

    Widget body;
    if (user == null || !vm.orderLoaded) {
      body = const SkeletonList(count: 3);
    } else if (user.subscriptionActive) {
      body = const EmptyState(
        icon: Icons.verified_rounded,
        title: AppStrings.statusSubscribed,
        message: AppStrings.alreadySubscribed,
      );
    } else if (user.hasPendingSubscription) {
      body = ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          NoticeBanner.warning(AppStrings.orderPendingMessage, title: AppStrings.orderPendingTitle),
          if (vm.latestOrder != null) _OrderSummary(order: vm.latestOrder!),
        ],
      );
    } else if (vm.showRejected) {
      final order = vm.latestOrder!;
      body = ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          NoticeBanner.error(
            AppStrings.rejectionReason(order.rejectionReason ?? '—'),
            title: AppStrings.orderRejectedTitle,
          ),
          _OrderSummary(order: order),
          SizedBox(height: 2.h),
          PrimaryButton(label: AppStrings.resubmit, onPressed: vm.startResubmit),
        ],
      );
    } else {
      body = const _SubscriptionForm();
    }

    return Scaffold(
      appBar: const AppBarX(title: AppStrings.depositTitle),
      body: SafeArea(child: body),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final SubscriptionOrder order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          InfoRow(label: AppStrings.amount, value: Formatters.pkr(order.amount)),
          InfoRow(label: AppStrings.transactionId, value: order.transactionId),
          InfoRow(label: AppStrings.submitted, value: Formatters.dateTime(order.createdAt)),
        ],
      ),
    );
  }
}

class _SubscriptionForm extends StatefulWidget {
  const _SubscriptionForm();

  @override
  State<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<_SubscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _txn = TextEditingController();

  @override
  void dispose() {
    _txn.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<SubscriptionViewModel>();
    final valid = _formKey.currentState?.validate() ?? false;
    if (vm.proofBytes == null) vm.setProofError(AppStrings.screenshotRequired);
    if (!valid || vm.proofBytes == null) return;

    final ok = await vm.submit(transactionId: _txn.text);
    if (!mounted) return;
    if (ok) {
      _txn.clear();
      await SuccessDialog.show(
        context,
        title: AppStrings.subscriptionSubmittedTitle,
        message: AppStrings.subscriptionSubmittedMessage,
      );
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionViewModel>();
    final settings = context.select<SessionViewModel, AppSettings?>((s) => s.settings);
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);

    if (settings == null) {
      return const EmptyState(
        icon: Icons.settings_rounded,
        title: AppStrings.settingsUnavailable,
        message: AppStrings.settingsNotLoaded,
      );
    }
    final canSend = online && settings.bank.isConfigured && !vm.compressing;

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Text(AppStrings.subscriptionIntro, style: AppTextStyles.bodySecondary),
          SizedBox(height: 2.h),
          BankDetailsCard(bank: settings.bank),
          SizedBox(height: 2.5.h),
          Container(
            padding: EdgeInsets.all(4.w),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(3.w)),
            child: Row(
              children: [
                Expanded(child: Text(AppStrings.amount, style: AppTextStyles.subtitle)),
                Text(
                  Formatters.pkr(settings.subscriptionPrice),
                  style: AppTextStyles.headline.copyWith(color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          AppTextField(
            controller: _txn,
            label: AppStrings.transactionId,
            prefixIcon: Icons.receipt_long_rounded,
            validator: Validators.transactionId,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(40),
            ],
          ),
          ImagePickerField(
            label: AppStrings.paymentScreenshot,
            bytes: vm.proofBytes,
            isProcessing: vm.compressing,
            errorText: vm.proofError,
            onPick: vm.pickProof,
          ),
          if (!online) NoticeBanner.warning(AppStrings.errorOffline),
          PrimaryButton(label: AppStrings.submitPayment, isLoading: vm.isLoading, onPressed: canSend ? _submit : null),
        ],
      ),
    );
  }
}
