import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/route_names.dart';
import '../widgets/state_views.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: AppStrings.pageNotFound,
        message: AppStrings.pageNotFoundMessage,
        actionLabel: AppStrings.goHome,
        actionIcon: Icons.home_rounded,
        onAction: () => context.go(Routes.splash),
      ),
    );
  }
}
