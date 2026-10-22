import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/video_task.dart';
import '../../../data/repositories/watch_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/tasks_view_model.dart';
import '../../../viewmodels/user/video_player_view_model.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/success_dialog.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key, required this.task});

  final VideoTask task;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionViewModel>();
    return ChangeNotifierProvider(
      create: (ctx) => VideoPlayerViewModel(
        task: task,
        uid: session.uid!,
        settings: session.settingsOrDefault,
        repo: ctx.read<WatchRepository>(),
        tasks: ctx.read<TasksViewModel>(),
      ),
      child: const _PlayerView(),
    );
  }
}

class _PlayerView extends StatefulWidget {
  const _PlayerView();

  @override
  State<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<_PlayerView> {
  late final VideoPlayerViewModel _vm = context.read<VideoPlayerViewModel>();
  WatchPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onPhase);
  }

  @override
  void dispose() {
    _vm.removeListener(_onPhase);
    super.dispose();
  }

  void _onPhase() {
    final phase = _vm.phase;
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    if (phase == WatchPhase.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await SuccessDialog.show(
          context,
          title: AppStrings.rewardEarnedTitle,
          message: AppStrings.rewardEarnedMessage(Formatters.pkr(_vm.earned ?? _vm.reward)),
        );
        if (mounted) context.pop();
      });
    } else if (phase == WatchPhase.stillWatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askStillWatching());
    }
  }

  Future<void> _askStillWatching() async {
    if (!mounted) return;
    final answered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _StillWatchingDialog(),
    );
    _vm.answerStillWatching(answered ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VideoPlayerViewModel>();
    final busy = vm.phase == WatchPhase.preparing || vm.phase == WatchPhase.completing;
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── header ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 2.h),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.black, AppColors.primaryDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: EdgeInsets.all(2.2.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2.8.w),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 4.5.w),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      AppStrings.watchAndEarn,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.sp,
                      ),
                    ),
                    const Spacer(),
                    // reward badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(2.5.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_rounded, color: AppColors.white, size: 4.w),
                          SizedBox(width: 1.w),
                          Text(
                            Formatters.pkr(vm.reward),
                            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12.5.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── video player ──
              Stack(
                children: [
                  IgnorePointer(
                    child: YoutubePlayer(
                      controller: vm.controller,
                      showVideoProgressIndicator: false,
                      bufferIndicator: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  if (busy)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.scrim,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppColors.white),
                              SizedBox(height: 1.h),
                              Text(
                                vm.phase == WatchPhase.preparing
                                    ? AppStrings.startingSession
                                    : AppStrings.completingTask,
                                style: AppTextStyles.body.copyWith(color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── progress bar ──
              LinearProgressIndicator(
                value: vm.progress,
                minHeight: 0.6.h,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
              ),

              // ── info section ──
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // title + progress card
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vm.task.title, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700)),
                          SizedBox(height: 1.h),
                          // progress row
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8FA),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, color: Colors.grey.shade500, size: 4.5.w),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    AppStrings.watchProgress(
                                      Formatters.duration(vm.watchedSeconds),
                                      Formatters.duration(vm.task.durationSeconds),
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(2.w),
                                  ),
                                  child: Text(
                                    AppStrings.rewardLabel(Formatters.pkr(vm.reward)),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // status / action buttons
                    ..._statusArea(context, vm),

                    SizedBox(height: 2.h),

                    NoticeBanner.info(AppStrings.watchInstructions),

                    if (vm.task.description.isNotEmpty) ...[
                      SizedBox(height: 1.5.h),
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 14.sp),
                            ),
                            SizedBox(height: 0.8.h),
                            Text(vm.task.description, style: AppTextStyles.bodySecondary),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _statusArea(BuildContext context, VideoPlayerViewModel vm) {
    switch (vm.phase) {
      case WatchPhase.interrupted:
        return [
          NoticeBanner.error(vm.interruptMessage ?? '', title: vm.interruptTitle),
          SizedBox(height: 1.h),
          _ActionButton(label: AppStrings.restartVideo, icon: Icons.replay_rounded, onTap: vm.restart),
        ];
      case WatchPhase.failed:
        return [
          NoticeBanner.error(vm.interruptMessage ?? AppStrings.videoUnavailable),
          SizedBox(height: 1.h),
          _ActionButton(
            label: AppStrings.back,
            icon: Icons.arrow_back_rounded,
            outlined: true,
            onTap: () => context.pop(),
          ),
        ];
      case WatchPhase.playing:
      case WatchPhase.paused:
      case WatchPhase.ready:
        final playing = vm.phase == WatchPhase.playing;
        return [
          _ActionButton(
            label: playing ? AppStrings.pause : AppStrings.play,
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            outlined: playing,
            onTap: vm.togglePlay,
          ),
        ];
      case WatchPhase.preparing:
      case WatchPhase.stillWatching:
      case WatchPhase.completing:
      case WatchPhase.completed:
        return const [];
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ACTION BUTTON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.outlined = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: outlined ? AppColors.white : null,
          borderRadius: BorderRadius.circular(3.w),
          border: outlined ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outlined ? AppColors.primary : AppColors.white, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                color: outlined ? AppColors.primary : AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  STILL WATCHING DIALOG
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StillWatchingDialog extends StatefulWidget {
  const _StillWatchingDialog();

  @override
  State<_StillWatchingDialog> createState() => _StillWatchingDialogState();
}

class _StillWatchingDialogState extends State<_StillWatchingDialog> {
  static const int _seconds = 15;
  int _left = _seconds;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
        title: const Text(AppStrings.stillWatchingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.stillWatchingMessage, style: AppTextStyles.bodySecondary),
            SizedBox(height: 2.h),
            Text('$_left', style: AppTextStyles.display.copyWith(color: AppColors.primary)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Center(
                  child: Text(
                    AppStrings.stillWatchingButton,
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15.sp),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
