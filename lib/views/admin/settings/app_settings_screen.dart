import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'bank_tab.dart';
import 'content_tab.dart';
import 'pricing_tab.dart';
import 'support_tab.dart';
import 'system_tab.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          AdminSettingsViewModel(repo: ctx.read<SettingsRepository>(), session: ctx.read<SessionViewModel>()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final hasSettings = context.select<SessionViewModel, bool>((s) => s.hasSettings);
    if (!hasSettings) return const _CreateDefaults();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const AppBarX(
          title: AppStrings.appSettings,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: AppStrings.tabPricing),
              Tab(text: AppStrings.tabBank),
              Tab(text: AppStrings.tabSupport),
              Tab(text: AppStrings.tabContent),
              Tab(text: AppStrings.tabSystem),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(children: [PricingTab(), BankTab(), SupportTab(), ContentTab(), SystemTab()]),
        ),
      ),
    );
  }
}

class _CreateDefaults extends StatelessWidget {
  const _CreateDefaults();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSettingsViewModel>();
    return Scaffold(
      appBar: const AppBarX(title: AppStrings.appSettings),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const EmptyState(
                icon: Icons.settings_suggest_rounded,
                title: AppStrings.settingsMissingTitle,
                message: AppStrings.settingsMissingMessage,
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: PrimaryButton(
                  label: AppStrings.createDefaultSettings,
                  isLoading: vm.isLoading,
                  onPressed: () async {
                    final ok = await vm.createDefaults();
                    if (!context.mounted) return;
                    ok
                        ? AppSnackbars.success(context, AppStrings.defaultsCreated)
                        : AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared save handler for every settings tab.
Future<void> saveSettingsWithFeedback(BuildContext context, Future<bool> Function() save) async {
  final vm = context.read<AdminSettingsViewModel>();
  final ok = await save();
  if (!context.mounted) return;
  ok
      ? AppSnackbars.success(context, AppStrings.settingsSaved)
      : AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
}
