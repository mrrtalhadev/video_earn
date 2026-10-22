import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/video_task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../viewmodels/admin/admin_tasks_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminTasksViewModel(ctx.read<TaskRepository>()),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  static const _labels = {
    AdminTaskFilter.all: AppStrings.all,
    AdminTaskFilter.admin: AppStrings.filterAdmin,
    AdminTaskFilter.promote: AppStrings.filterPromote,
    AdminTaskFilter.expired: AppStrings.filterExpired,
  };

  Future<void> _openEditor(BuildContext context, VideoTask? task) async {
    final vm = context.read<AdminTasksViewModel>();
    final saved = await context.push<bool>(Routes.adminTaskEdit, extra: task);
    if (saved == true) await vm.refreshAll();
  }

  Future<void> _purge(BuildContext context) async {
    final vm = context.read<AdminTasksViewModel>();
    final n = await vm.countExpired();
    if (n == null || n == 0 || !context.mounted) return;
    final ok = await ConfirmDialog.show(
      context,
      message: AppStrings.purgeExpiredConfirm(n),
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!ok) return;
    final deleted = await vm.purgeExpired();
    if (!context.mounted) return;
    deleted == null
        ? AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric)
        : AppSnackbars.success(context, AppStrings.taskDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminTasksViewModel>();
    return Scaffold(
      appBar: AppBarX(
        title: AppStrings.taskManagement,
        actions: [
          IconButton(
            tooltip: AppStrings.purgeExpired,
            icon: const Icon(Icons.auto_delete_outlined),
            onPressed: () => _purge(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addTask),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 7.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                children: AdminTaskFilter.values
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
            Expanded(
              child: PagedListView<VideoTask>(
                list: vm.current,
                emptyTitle: AppStrings.noTasksAdmin,
                emptyMessage: AppStrings.noTasksAdminMessage,
                emptyIcon: Icons.video_library_outlined,
                itemBuilder: (ctx, t) => _AdminTaskTile(task: t, onEdit: () => _openEditor(ctx, t)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTaskTile extends StatelessWidget {
  const _AdminTaskTile({required this.task, required this.onEdit});

  final VideoTask task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminTasksViewModel>();
    final expired = task.isExpired();
    return AppCard(
      padding: EdgeInsets.all(3.w),
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: CachedNetworkImage(
              imageUrl: task.thumbnailUrl,
              width: 28.w,
              height: 16.w,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                width: 28.w,
                height: 16.w,
                color: AppColors.surface,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(Formatters.duration(task.durationSeconds), style: AppTextStyles.caption),
                SizedBox(height: 0.6.h),
                Wrap(
                  spacing: 1.5.w,
                  runSpacing: 0.5.h,
                  children: [
                    task.source == TaskSource.promote
                        ? StatusChip.warning(AppStrings.sourcePromote)
                        : StatusChip.neutral(AppStrings.sourceAdmin),
                    if (expired)
                      StatusChip.negative(AppStrings.statusExpired)
                    else if (task.isActive)
                      StatusChip.positive(AppStrings.statusActive)
                    else
                      StatusChip.neutral(AppStrings.statusInactive),
                  ],
                ),
                if (task.source == TaskSource.promote) ...[
                  SizedBox(height: 0.5.h),
                  Text(AppStrings.expiresOn(Formatters.dateTime(task.expiresAt)), style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                message: AppStrings.deleteTaskConfirm,
                confirmLabel: AppStrings.delete,
                destructive: true,
              );
              if (!ok) return;
              final done = await vm.delete(task.id);
              if (!context.mounted) return;
              done
                  ? AppSnackbars.success(context, AppStrings.taskDeleted)
                  : AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
            },
          ),
        ],
      ),
    );
  }
}
