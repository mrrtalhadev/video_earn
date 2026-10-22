import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'app_dependencies.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/admin_user_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/promote_repository.dart';
import 'data/repositories/proof_repository.dart';
import 'data/repositories/referral_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/watch_repository.dart';
import 'data/repositories/withdraw_repository.dart';
import 'viewmodels/auth/session_view_model.dart';
import 'viewmodels/connectivity_view_model.dart';
import 'viewmodels/user/tasks_view_model.dart';
import 'views/widgets/offline_banner.dart';

/// Root widget: repositories → session → router, inside ResponsiveSizer.
class App extends StatefulWidget {
  const App({super.key, this.dependencies, this.connectivity});

  /// Defaults to the Firebase-backed repositories.
  final AppDependencies? dependencies;

  /// Defaults to the platform connectivity listener.
  final ConnectivityViewModel Function()? connectivity;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDependencies _deps = widget.dependencies ?? AppDependencies.firebase();
  late final SessionViewModel _session = SessionViewModel(
    auth: _deps.auth,
    users: _deps.users,
    settings: _deps.settings,
  );
  late final GoRouter _router = createRouter(_session);

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _deps;
    return MultiProvider(
      providers: [
        Provider<ProofRepository>.value(value: d.proofs),
        Provider<ReferralRepository>.value(value: d.referrals),
        Provider<AuthRepository>.value(value: d.auth),
        Provider<UserRepository>.value(value: d.users),
        Provider<SettingsRepository>.value(value: d.settings),
        Provider<TaskRepository>.value(value: d.tasks),
        Provider<WatchRepository>.value(value: d.watch),
        Provider<WalletRepository>.value(value: d.wallet),
        Provider<SubscriptionRepository>.value(value: d.subscriptions),
        Provider<WithdrawRepository>.value(value: d.withdrawals),
        Provider<PromoteRepository>.value(value: d.promote),
        Provider<StatsRepository>.value(value: d.stats),
        Provider<AdminUserRepository>.value(value: d.adminUsers),
        ChangeNotifierProvider<SessionViewModel>.value(value: _session),
        ChangeNotifierProvider<ConnectivityViewModel>(
          create: (_) => widget.connectivity?.call() ?? ConnectivityViewModel(),
        ),
        ChangeNotifierProxyProvider<SessionViewModel, TasksViewModel>(
          create: (ctx) => TasksViewModel(ctx.read<TaskRepository>()),
          update: (_, session, vm) => vm!..updateUid(session.uid),
        ),
      ],
      child: ResponsiveSizer(
        builder: (context, orientation, screenType) => MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
