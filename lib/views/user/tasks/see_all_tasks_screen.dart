import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/app_user.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/tasks_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_card.dart';
import 'task_actions.dart';

class SeeAllTasksScreen extends StatefulWidget {
  const SeeAllTasksScreen({super.key});

  @override
  State<SeeAllTasksScreen> createState() => _SeeAllTasksScreenState();
}

class _SeeAllTasksScreenState extends State<SeeAllTasksScreen> {
  static const _labels = {
    TaskFilter.all: AppStrings.all,
    TaskFilter.pending: AppStrings.filterPending,
    TaskFilter.completed: AppStrings.filterCompleted,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TasksViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final user = context.select<SessionViewModel, AppUser?>((s) => s.user);
    final reward = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.videoReward);
    final page = vm.page;

    Widget body;
    if (!vm.loaded && !vm.hasError) {
      body = const SkeletonList(count: 3);
    } else if (vm.hasError && vm.tasks.isEmpty) {
      body = ErrorState(message: vm.errorMessage, onRetry: vm.load);
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
          itemCount: page.isEmpty ? 1 : page.length + 1,
          itemBuilder: (context, i) {
            if (page.isEmpty) {
              return SizedBox(
                height: 60.h,
                child: const EmptyState(
                  title: AppStrings.nothingHere,
                  message: AppStrings.nothingHereMessage,
                  icon: Icons.video_library_outlined,
                ),
              );
            }
            if (i == page.length) {
              return vm.hasMorePages
                  ? TextButton(onPressed: vm.showMore, child: const Text(AppStrings.loadMore))
                  : SizedBox(height: 2.h);
            }
            final t = page[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 2.5.h),
              child: TaskCard(
                task: t,
                reward: reward,
                locked: !(user?.canEarn ?? false),
                completed: vm.isCompleted(t.id),
                onTap: () => openTask(context, t),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarX(title: AppStrings.seeAllTasks),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 7.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                children: TaskFilter.values
                    .map(
                      (f) => Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: ChoiceChip(
                          label: Text(_labels[f]!),
                          selected: vm.filter == f,
                          onSelected: (_) => vm.setFilter(f),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
