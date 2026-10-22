import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/video_task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../viewmodels/admin/task_edit_view_model.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/number_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/video_verify_panel.dart';

class TaskEditScreen extends StatelessWidget {
  const TaskEditScreen({super.key, this.task});

  final VideoTask? task;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TaskEditViewModel(ctx.read<TaskRepository>(), existing: task),
      child: _TaskEditView(task: task),
    );
  }
}

class _TaskEditView extends StatefulWidget {
  const _TaskEditView({this.task});

  final VideoTask? task;

  @override
  State<_TaskEditView> createState() => _TaskEditViewState();
}

class _TaskEditViewState extends State<_TaskEditView> {
  final _formKey = GlobalKey<FormState>();
  late final _url = TextEditingController(text: widget.task?.youtubeUrl);
  late final _title = TextEditingController(text: widget.task?.title);
  late final _desc = TextEditingController(text: widget.task?.description);
  late final _order = TextEditingController(text: '${widget.task?.order ?? 0}');
  late bool _active = widget.task?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_url, _title, _desc, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<TaskEditViewModel>();
    if (!vm.canSave) {
      AppSnackbars.error(context, AppStrings.verifyFirst);
      return;
    }
    final ok = await vm.save(
      title: _title.text,
      description: _desc.text,
      isActive: _active,
      order: int.parse(_order.text.trim()),
    );
    if (!mounted) return;
    if (ok) {
      AppSnackbars.success(context, AppStrings.taskSaved);
      context.pop(true);
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskEditViewModel>();
    final maxMinutes = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.maxVideoMinutes);

    return Scaffold(
      appBar: AppBarX(title: widget.task == null ? AppStrings.addTask : AppStrings.editTask),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              AppTextField(
                controller: _url,
                label: AppStrings.youtubeLink,
                prefixIcon: Icons.link_rounded,
                keyboardType: TextInputType.url,
                readOnly: vm.isPromoted,
                validator: Validators.youtubeUrl,
                onChanged: vm.onUrlChanged,
              ),
              if (!vm.isPromoted)
                VideoVerifyPanel(
                  videoId: vm.videoId,
                  maxMinutes: maxMinutes,
                  onResult: (r) {
                    vm.onVerified(r);
                    if (r != null && _title.text.trim().isEmpty) {
                      _title.text = r.title.length > 100 ? r.title.substring(0, 100) : r.title;
                    }
                  },
                ),
              SizedBox(height: 2.h),
              AppTextField(controller: _title, label: AppStrings.videoTitle, validator: Validators.title),
              AppTextField(
                controller: _desc,
                label: '${AppStrings.videoDescription} ${AppStrings.optional}',
                maxLines: 3,
                validator: Validators.description,
              ),
              NumberField(controller: _order, label: AppStrings.sortOrderLabel, validator: Validators.nonNegativeInt),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text(AppStrings.activeLabel),
              ),
              if (!vm.canSave) ...[Text(AppStrings.verifyFirst, style: AppTextStyles.caption), SizedBox(height: 1.h)],
              PrimaryButton(label: AppStrings.save, isLoading: vm.isLoading, onPressed: vm.canSave ? _save : null),
            ],
          ),
        ),
      ),
    );
  }
}
