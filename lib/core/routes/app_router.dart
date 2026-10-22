import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/video_task.dart';
import '../../viewmodels/auth/session_view_model.dart';
import '../../views/admin/admin_more_screen.dart';
import '../../views/admin/dashboard_screen.dart';
import '../../views/admin/orders/promote_orders_management_screen.dart';
import '../../views/admin/orders/subscription_management_screen.dart';
import '../../views/admin/orders/withdraw_management_screen.dart';
import '../../views/admin/promote_plans_screen.dart';
import '../../views/admin/settings/app_settings_screen.dart';
import '../../views/admin/tasks/task_edit_screen.dart';
import '../../views/admin/tasks/task_management_screen.dart';
import '../../views/admin/users/user_detail_screen.dart';
import '../../views/admin/users/users_list_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/shell/not_found_screen.dart';
import '../../views/shell/shells.dart';
import '../../views/splash/app_status_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/user/home/home_screen.dart';
import '../../views/user/player/video_player_screen.dart';
import '../../views/user/profile/edit_profile_screen.dart';
import '../../views/user/profile/info_screens.dart';
import '../../views/user/profile/profile_screen.dart';
import '../../views/user/profile/referral_screen.dart';
import '../../views/user/promote/my_promote_orders_screen.dart';
import '../../views/user/promote/promote_screen.dart';
import '../../views/user/subscription/subscription_purchase_screen.dart';
import '../../views/user/tasks/see_all_tasks_screen.dart';
import '../../views/user/wallet/history_screen.dart';
import '../../views/user/wallet/wallet_screen.dart';
import '../../views/user/wallet/withdraw_screen.dart';
import 'role_guard.dart';
import 'route_names.dart';

/// Builds the app router. Created once; re-evaluates redirects whenever the
/// session changes (sign-in/out, role, maintenance, blocked).
GoRouter createRouter(SessionViewModel session) {
  GoRoute page(String path, Widget Function(GoRouterState s) build) => GoRoute(path: path, builder: (_, s) => build(s));

  StatefulShellBranch branch(String path, Widget child) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => child)],
  );

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (_, state) =>
        roleGuard(status: session.status, splashDone: session.splashDone, location: state.matchedLocation),
    errorBuilder: (_, _) => const NotFoundScreen(),
    routes: [
      // Startup / status
      page(Routes.splash, (_) => const SplashScreen()),
      page(Routes.maintenance, (_) => const AppStatusScreen(kind: AppStatusKind.maintenance)),
      page(Routes.updateRequired, (_) => const AppStatusScreen(kind: AppStatusKind.updateRequired)),
      page(Routes.incomplete, (_) => const AppStatusScreen(kind: AppStatusKind.incomplete)),

      // Auth
      page(Routes.login, (_) => const LoginScreen()),
      page(Routes.signup, (_) => const SignupScreen()),
      page(Routes.forgotPassword, (_) => const ForgotPasswordScreen()),

      // User
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => UserShell(shell: shell),
        branches: [
          branch(Routes.home, const HomeScreen()),
          branch(Routes.wallet, const WalletScreen()),
          branch(Routes.promote, const PromoteScreen()),
          branch(Routes.profile, const ProfileScreen()),
        ],
      ),
      page(Routes.tasks, (_) => const SeeAllTasksScreen()),
      GoRoute(
        path: Routes.player,
        // The task is passed in-memory; without it (e.g. restored URL) go home.
        redirect: (_, s) => s.extra is VideoTask ? null : Routes.home,
        builder: (_, s) => VideoPlayerScreen(task: s.extra! as VideoTask),
      ),
      page(Routes.subscribe, (_) => const SubscriptionPurchaseScreen()),
      page(Routes.withdraw, (_) => const WithdrawScreen()),
      page(Routes.history, (_) => const HistoryScreen()),
      page(Routes.referral, (_) => const ReferralScreen()),
      page(Routes.faq, (_) => const FaqScreen()),
      page(Routes.about, (_) => const ContentScreen(kind: ContentKind.about)),
      page(Routes.terms, (_) => const ContentScreen(kind: ContentKind.terms)),
      page(Routes.contact, (_) => const ContactUsScreen()),
      page(Routes.myPromoteOrders, (_) => const MyPromoteOrdersScreen()),
      page(Routes.editProfile, (_) => const EditProfileScreen()),

      // Admin
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(shell: shell),
        branches: [
          branch(Routes.adminDashboard, const DashboardScreen()),
          branch(Routes.adminUsers, const UsersListScreen()),
          branch(Routes.adminSubscriptions, const SubscriptionManagementScreen()),
          branch(Routes.adminWithdrawals, const WithdrawManagementScreen()),
          branch(Routes.adminMore, const AdminMoreScreen()),
        ],
      ),
      page('${Routes.adminUserDetail}/:uid', (s) => UserDetailScreen(uid: s.pathParameters['uid']!)),
      page(Routes.adminTasks, (_) => const TaskManagementScreen()),
      page(Routes.adminTaskEdit, (s) => TaskEditScreen(task: s.extra is VideoTask ? s.extra! as VideoTask : null)),
      page(Routes.adminPromoteOrders, (_) => const PromoteOrdersManagementScreen()),
      page(Routes.adminPromotePlans, (_) => const PromotePlansScreen()),
      page(Routes.adminSettings, (_) => const AppSettingsScreen()),
    ],
  );
}
