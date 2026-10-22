import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth/auth_view_model.dart';
import '../../viewmodels/auth/session_view_model.dart';
import '../../viewmodels/connectivity_view_model.dart';
import '../widgets/app_text_field.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthViewModel(auth: ctx.read<AuthRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _referral]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthViewModel>().signup(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      referralCode: _referral.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);
    final showGeneralError = vm.hasError && vm.referralError == null && vm.errorMessage != null;

    return AuthScaffold(
      title: AppStrings.signupTitle,
      subtitle: AppStrings.signupSubtitle,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showGeneralError) NoticeBanner.error(vm.errorMessage!),
              if (!online) NoticeBanner.warning(AppStrings.errorOffline),
              const AuthSectionLabel(AppStrings.signupSectionDetails, icon: Icons.badge_rounded),
              AppTextField(
                controller: _name,
                label: AppStrings.name,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
                autofillHints: const [AutofillHints.name],
              ),
              AppTextField(
                controller: _email,
                label: AppStrings.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              AppTextField(
                controller: _phone,
                label: AppStrings.phone,
                hint: AppStrings.phoneHint,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]'))],
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              SizedBox(height: 1.h),
              const AuthSectionLabel(AppStrings.signupSectionSecurity, icon: Icons.shield_rounded),
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              AppTextField(
                controller: _confirm,
                label: AppStrings.confirmPassword,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.confirmPassword(() => _password.text),
              ),
              SizedBox(height: 1.h),
              const AuthSectionLabel(AppStrings.signupSectionReferral, icon: Icons.card_giftcard_rounded),
              AppTextField(
                controller: _referral,
                label: AppStrings.referralCodeOptional,
                prefixIcon: Icons.card_giftcard_rounded,
                textCapitalization: TextCapitalization.characters,
                validator: Validators.referralCodeOptional,
                errorText: vm.referralError,
                onChanged: (_) {
                  vm.clearReferralError();
                  setState(() {});
                },
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(8),
                  _UpperCaseFormatter(),
                ],
                suffix: _referral.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _referral.clear();
                          vm.clearReferralError();
                          setState(() {});
                        },
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_rounded, size: 4.w, color: AppColors.success),
                  SizedBox(width: 2.w),
                  Expanded(child: Text(AppStrings.agreeTerms, style: AppTextStyles.caption)),
                ],
              ),
              SizedBox(height: 2.5.h),
              PrimaryButton(label: AppStrings.signup, isLoading: vm.isLoading, onPressed: online ? _submit : null),
              SizedBox(height: 2.h),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.haveAccount, style: AppTextStyles.bodySecondary),
                  TextButton(onPressed: () => context.go(Routes.login), child: const Text(AppStrings.login)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
