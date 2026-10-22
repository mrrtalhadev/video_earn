import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth/auth_view_model.dart';
import '../../viewmodels/auth/session_view_model.dart';
import '../../viewmodels/connectivity_view_model.dart';
import '../widgets/app_text_field.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthViewModel(auth: ctx.read<AuthRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthViewModel>().login(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final notice = context.select<SessionViewModel, String?>((s) => s.notice);
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);

    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notice != null) NoticeBanner.error(notice, title: AppStrings.blockedTitle),
              if (vm.hasError && vm.errorMessage != null) NoticeBanner.error(vm.errorMessage!),
              if (!online) NoticeBanner.warning(AppStrings.errorOffline),
              AppTextField(
                controller: _email,
                label: AppStrings.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: const Text(AppStrings.forgotPassword),
                ),
              ),
              SizedBox(height: 1.h),
              PrimaryButton(label: AppStrings.login, isLoading: vm.isLoading, onPressed: online ? _submit : null),
              SizedBox(height: 3.h),
              const AuthDivider(AppStrings.noAccount),
              SizedBox(height: 2.h),
              PrimaryButton(
                label: AppStrings.signupTitle,
                icon: Icons.person_add_alt_1_rounded,
                outlined: true,
                onPressed: () => context.go(Routes.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
