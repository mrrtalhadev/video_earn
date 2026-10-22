/// Route paths. Keep in sync with `app_router.dart`.
abstract final class Routes {
  // Startup / status
  static const String splash = '/';
  static const String maintenance = '/maintenance';
  static const String updateRequired = '/update-required';
  static const String incomplete = '/account-incomplete';

  // Auth
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // User shell tabs
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String promote = '/promote';
  static const String profile = '/profile';

  // User screens
  static const String tasks = '/tasks';
  static const String player = '/player';
  static const String subscribe = '/subscribe';
  static const String withdraw = '/withdraw';
  static const String history = '/history';
  static const String referral = '/referral';
  static const String faq = '/faq';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String terms = '/terms';
  static const String myPromoteOrders = '/my-promotions';
  static const String editProfile = '/edit-profile';

  // Admin
  static const String adminRoot = '/admin';
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/user'; // + /:uid
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminWithdrawals = '/admin/withdrawals';
  static const String adminMore = '/admin/more';
  static const String adminTasks = '/admin/tasks';
  static const String adminTaskEdit = '/admin/task-edit';
  static const String adminPromoteOrders = '/admin/promote-orders';
  static const String adminPromotePlans = '/admin/promote-plans';
  static const String adminSettings = '/admin/settings';

  static const Set<String> authRoutes = {login, signup, forgotPassword};
  static const Set<String> statusRoutes = {splash, maintenance, updateRequired, incomplete};

  static String adminUser(String uid) => '$adminUserDetail/$uid';
}
