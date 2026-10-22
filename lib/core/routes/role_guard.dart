import '../../viewmodels/auth/session_view_model.dart';
import 'route_names.dart';

/// Pure redirect logic for the router, based on the session state.
/// Returns the path to redirect to, or null to stay.
String? roleGuard({required SessionStatus status, required bool splashDone, required String location}) {
  if (!splashDone) return location == Routes.splash ? null : Routes.splash;

  final isAuthRoute = Routes.authRoutes.contains(location);
  final isAdminRoute = location == Routes.adminRoot || location.startsWith('${Routes.adminRoot}/');
  final isStatusRoute = Routes.statusRoutes.contains(location);

  switch (status) {
    case SessionStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case SessionStatus.signedOut:
      return isAuthRoute ? null : Routes.login;
    case SessionStatus.maintenance:
      return location == Routes.maintenance ? null : Routes.maintenance;
    case SessionStatus.updateRequired:
      return location == Routes.updateRequired ? null : Routes.updateRequired;
    case SessionStatus.incomplete:
      return location == Routes.incomplete ? null : Routes.incomplete;
    case SessionStatus.admin:
      return isAdminRoute ? null : Routes.adminDashboard;
    case SessionStatus.user:
      return (isAuthRoute || isAdminRoute || isStatusRoute) ? Routes.home : null;
  }
}
