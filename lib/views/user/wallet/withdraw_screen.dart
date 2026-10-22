import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/withdraw_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/connectivity_view_model.dart';
import '../../../viewmodels/user/withdraw_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/number_field.dart';
import '../../widgets/success_dialog.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => WithdrawViewModel(repo: ctx.read<WithdrawRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _WithdrawView(),
    );
  }
}

class _WithdrawView extends StatefulWidget {
  const _WithdrawView();

  @override
  State<_WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<_WithdrawView> {
  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    for (final c in [_holder, _bank, _account, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<WithdrawViewModel>();
    final amount = int.parse(_amount.text.trim());
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.withdrawConfirmTitle,
      message: AppStrings.withdrawConfirmMessage(
        Formatters.pkr(amount),
        '${_bank.text.trim()} · ${Validators.normalizeAccount(_account.text)}',
      ),
    );
    if (!confirmed || !mounted) return;

    final ok = await vm.submit(
      amount: amount,
      accountHolderName: _holder.text,
      bankName: _bank.text,
      accountNumber: _account.text,
    );
    if (!mounted) return;
    if (ok) {
      await SuccessDialog.show(
        context,
        title: AppStrings.withdrawSubmittedTitle,
        message: AppStrings.withdrawSubmittedMessage,
      );
      if (mounted) context.pop();
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SessionViewModel>();
    final vm = context.watch<WithdrawViewModel>();
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);
    final user = vm.user;
    final s = vm.settings;
    final blocked = vm.blockedReason;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _WithdrawHeader(balance: user?.balance ?? 0, settings: s),
                SizedBox(height: 2.5.h),

                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 5.h, 4.w, 3.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (blocked != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.5.h),
                          child: NoticeBanner.warning(blocked),
                        ),
                      if (!online)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.5.h),
                          child: NoticeBanner.warning(AppStrings.errorOffline),
                        ),

                      // ── form card ──
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Details',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                            ),
                            SizedBox(height: 2.h),
                            AppTextField(
                              controller: _holder,
                              label: AppStrings.accountHolderName,
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.accountHolder,
                              enabled: blocked == null,
                            ),
                            AppTextField(
                              controller: _bank,
                              label: AppStrings.bankName,
                              prefixIcon: Icons.account_balance_outlined,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => Validators.maxLength(v, 100, isRequired: true),
                              enabled: blocked == null,
                            ),
                            AppTextField(
                              controller: _account,
                              label: AppStrings.accountNumber,
                              prefixIcon: Icons.numbers_rounded,
                              textCapitalization: TextCapitalization.characters,
                              validator: Validators.accountNumber,
                              enabled: blocked == null,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]'))],
                            ),
                            NumberField(
                              controller: _amount,
                              label: AppStrings.withdrawAmount,
                              prefixIcon: Icons.payments_outlined,
                              validator: Validators.amountBetween(s.minWithdraw, user?.balance ?? 0),
                              readOnly: blocked != null,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.5.h),

                      // ── submit button ──
                      GestureDetector(
                        onTap: blocked == null && online && !vm.isLoading ? _submit : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: blocked == null && online ? 1.0 : 0.5,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 1.8.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(3.w),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: vm.isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 5.w,
                                      height: 5.w,
                                      child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.north_east_rounded, color: AppColors.white, size: 5.w),
                                      SizedBox(width: 2.w),
                                      Text(
                                        AppStrings.submitWithdraw,
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  WITHDRAW HEADER — dark gradient + balance + info chips
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _WithdrawHeader extends StatelessWidget {
  const _WithdrawHeader({required this.balance, required this.settings});
  final int balance;
  final dynamic settings;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 10.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.black, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // app bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          padding: EdgeInsets.all(2.2.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2.8.w),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 4.5.w),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        AppStrings.withdrawTitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // balance
                  Column(
                    children: [
                      Text(
                        AppStrings.availableBalance,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.pkr(balance),
                          style: AppTextStyles.display.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 32.sp,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ],
          ),
        ),

        // floating info card
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: -4.5.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -3.w,
                  top: -2.h,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Minimum',
                      value: Formatters.pkr(settings.minWithdraw),
                    ),
                    _VertDivider(),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: 'Cooldown',
                      value: '${settings.withdrawCooldownDays} Days',
                    ),
                    _VertDivider(),
                    _InfoChip(icon: Icons.speed_rounded, label: 'Processing', value: '1-3 Days'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.75), size: 4.5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16.5.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.2.h),
          Text(
            label,
            style: TextStyle(color: AppColors.white, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 5.h, color: AppColors.white.withValues(alpha: 0.12));
  }
}
