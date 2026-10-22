import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth/auth_view_model.dart';
import '../../viewmodels/auth/session_view_model.dart';
import '../../viewmodels/base_view_model.dart';
import '../../viewmodels/connectivity_view_model.dart';
import '../widgets/app_text_field.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_button.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthViewModel(auth: ctx.read<AuthRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _ForgotView(),
    );
  }
}

class _ForgotView extends StatefulWidget {
  const _ForgotView();

  @override
  State<_ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<_ForgotView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthViewModel>().sendReset(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);

    return AuthScaffold(
      title: AppStrings.resetPassword,
      subtitle: AppStrings.resetPasswordSubtitle,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.state == ViewState.success) NoticeBanner.success(AppStrings.resetLinkSent),
            if (vm.hasError && vm.errorMessage != null) NoticeBanner.error(vm.errorMessage!),
            AppTextField(
              controller: _email,
              label: AppStrings.email,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: 1.h),
            PrimaryButton(label: AppStrings.sendResetLink, isLoading: vm.isLoading, onPressed: online ? _submit : null),
          ],
        ),
      ),
    );
  }
}
