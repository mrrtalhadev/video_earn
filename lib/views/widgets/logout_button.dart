import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth/session_view_model.dart';
import 'confirm_dialog.dart';

/// Red outlined "Log out" button with confirmation.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
      ),
      onPressed: () async {
        final ok = await ConfirmDialog.show(
          context,
          message: AppStrings.logoutConfirm,
          confirmLabel: AppStrings.logout,
          destructive: true,
        );
        if (ok && context.mounted) await context.read<SessionViewModel>().signOut();
      },
      icon: const Icon(Icons.logout_rounded),
      label: const Text(AppStrings.logout),
    );
  }
}
