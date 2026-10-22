// Boots the real app (router, role guard, providers, theme) with fake
// repositories and renders every screen on a small phone (360x740 dp).
// Any layout overflow or exception during build fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:video_earn/app.dart';
import 'package:video_earn/app_dependencies.dart';
import 'package:video_earn/core/routes/route_names.dart';
import 'package:video_earn/viewmodels/connectivity_view_model.dart';

import 'fakes.dart';

/// Logical phone width under test (spec: must work down to 320 dp).
double _width = 360;

Future<void> _boot(WidgetTester tester, AppDependencies deps) async {
  tester.view.physicalSize = Size(_width * 3, _width * 3 * 2.05);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(App(dependencies: deps, connectivity: () => ConnectivityViewModel.fixed()));
  // Splash minimum duration, then the session resolves and redirects.
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);
}

/// pumpAndSettle never settles with looping skeleton animations.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, String location) async {
  final ctx = tester.element(find.byType(Scaffold).first);
  GoRouter.of(ctx).go(location);
  await _settle(tester);
}

void main() {
  for (final width in [360.0, 320.0]) {
    group('${width.toInt()}dp', () {
      setUp(() => _width = width);
      _suite();
    });
  }
}

void _suite() {
  group('signed out', () {
    for (final route in [Routes.login, Routes.signup, Routes.forgotPassword]) {
      testWidgets('renders $route', (tester) async {
        await _boot(tester, fakeDependencies(signedIn: false));
        await _open(tester, route);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('user routes redirect to login', (tester) async {
      await _boot(tester, fakeDependencies(signedIn: false));
      await _open(tester, Routes.wallet);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('subscribed user', () {
    for (final route in [
      Routes.home,
      Routes.wallet,
      Routes.promote,
      Routes.profile,
      Routes.tasks,
      Routes.subscribe,
      Routes.withdraw,
      Routes.history,
      Routes.referral,
      Routes.faq,
      Routes.about,
      Routes.contact,
      Routes.terms,
      Routes.myPromoteOrders,
      Routes.editProfile,
    ]) {
      testWidgets('renders $route', (tester) async {
        await _boot(tester, fakeDependencies());
        await _open(tester, route);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('admin routes redirect home', (tester) async {
      await _boot(tester, fakeDependencies());
      await _open(tester, Routes.adminSettings);
      expect(find.text('Available Tasks'), findsOneWidget);
    });
  });

  group('unsubscribed user', () {
    for (final route in [Routes.home, Routes.subscribe, Routes.withdraw, Routes.wallet]) {
      testWidgets('renders $route', (tester) async {
        await _boot(tester, fakeDependencies(user: sampleUser(subscribed: false, balance: 0)));
        await _open(tester, route);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pending payment shows review state', (tester) async {
      await _boot(tester, fakeDependencies(user: sampleUser(subscribed: false, pending: true)));
      await _open(tester, Routes.subscribe);
      expect(find.text('Payment under review'), findsOneWidget);
    });
  });

  group('admin', () {
    for (final route in [
      Routes.adminDashboard,
      Routes.adminUsers,
      Routes.adminSubscriptions,
      Routes.adminWithdrawals,
      Routes.adminMore,
      Routes.adminUser('u1'),
      Routes.adminTasks,
      Routes.adminTaskEdit,
      Routes.adminPromoteOrders,
      Routes.adminPromotePlans,
      Routes.adminSettings,
    ]) {
      testWidgets('renders $route', (tester) async {
        await _boot(tester, fakeDependencies(admin: true));
        await _open(tester, route);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('admin lands on dashboard, not user home', (tester) async {
      await _boot(tester, fakeDependencies(admin: true));
      await _open(tester, Routes.home);
      expect(find.text('Admin Panel'), findsOneWidget);
    });
  });
}
