import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/video_task.dart';
import '../../data/repositories/watch_repository.dart';
import '../base_view_model.dart';
import 'tasks_view_model.dart';

enum WatchPhase { preparing, ready, playing, paused, stillWatching, interrupted, completing, completed, failed }

/// Strict watch tracking (spec §9).
///
/// * A watch session is written with a server timestamp before playback; the
///   rules only accept a completion once real server time ≥ minWatchPercent
///   of the duration has passed, and ≤ 3× the duration.
/// * [watchedSeconds] grows only while the player is `playing` AND the app is
///   in the foreground. Each tick compares the player position with the
///   counted time; a drift > 3s means a seek/skip → restart (new session).
/// * Backgrounding / locking the screen invalidates progress.
///
/// Residual risk: the rules prove elapsed time and one completion per task,
/// but cannot see the screen; someone could leave a video playing unwatched.
/// The optional "Are you still watching?" prompt mitigates this.
class VideoPlayerViewModel extends BaseViewModel with WidgetsBindingObserver {
  VideoPlayerViewModel({
    required this.task,
    required String uid,
    required AppSettings settings,
    required WatchRepository repo,
    required TasksViewModel tasks,
    Random? random,
  }) : _uid = uid,
       _settings = settings,
       _repo = repo,
       _tasks = tasks {
    controller = YoutubePlayerController(
      initialVideoId: task.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        hideControls: true,
        disableDragSeek: true,
        enableCaption: false,
        loop: false,
        mute: false,
      ),
    )..addListener(_onPlayer);
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    final rng = random ?? Random();
    // One random "still watching?" check between 30% and 80% of longer videos.
    if (task.durationSeconds >= 60) {
      final from = (task.durationSeconds * 0.3).round();
      final to = (task.durationSeconds * 0.8).round();
      _stillWatchingAt = from + rng.nextInt(max(1, to - from));
    }
    _startSession();
  }

  final VideoTask task;
  final String _uid;
  final AppSettings _settings;
  final WatchRepository _repo;
  final TasksViewModel _tasks;

  late final YoutubePlayerController controller;
  late final Timer _ticker;

  WatchPhase _phase = WatchPhase.preparing;
  String? _interruptMessage;
  String? _interruptTitle;
  int _watched = 0;
  DateTime? _sessionStartedLocal;
  bool _foreground = true;
  bool _pausedForInactive = false;
  bool _playWhenReady = false;
  int? _stillWatchingAt;
  bool _stillWatchingAsked = false;
  int? _earned;

  WatchPhase get phase => _phase;
  String? get interruptTitle => _interruptTitle;
  String? get interruptMessage => _interruptMessage;
  int get watchedSeconds => _watched;
  int get requiredSeconds => _settings.requiredWatchSeconds(task.durationSeconds);
  int get reward => _settings.videoReward;
  int? get earned => _earned;
  double get progress => task.durationSeconds == 0 ? 0 : (_watched / task.durationSeconds).clamp(0, 1);

  // ---------------------------------------------------------------- session

  Future<void> _startSession() async {
    _phase = WatchPhase.preparing;
    _watched = 0;
    _interruptMessage = null;
    _interruptTitle = null;
    notify();
    try {
      await _repo.startSession(uid: _uid, taskId: task.id);
      if (isDisposed) return;
      _sessionStartedLocal = DateTime.now();
      _phase = WatchPhase.ready;
      _playWhenReady = true;
      _maybeAutoPlay();
      notify();
    } catch (e) {
      debugPrint('Start session failed: $e');
      if (isDisposed) return;
      _fail(AppException.from(e).message);
    }
  }

  void _maybeAutoPlay() {
    if (_playWhenReady && controller.value.isReady && _foreground) {
      _playWhenReady = false;
      controller.seekTo(Duration.zero);
      controller.setPlaybackRate(1.0);
      controller.play();
    }
  }

  /// Restart from 0 with a fresh server-stamped session.
  Future<void> restart() async {
    controller.pause();
    controller.seekTo(Duration.zero);
    _stillWatchingAsked = false;
    await _startSession();
  }

  void togglePlay() {
    if (_phase == WatchPhase.playing) {
      controller.pause();
    } else if (_phase == WatchPhase.paused || _phase == WatchPhase.ready) {
      controller.setPlaybackRate(1.0);
      controller.play();
    }
  }

  // ---------------------------------------------------------------- player events

  void _onPlayer() {
    if (isDisposed) return;
    final v = controller.value;
    if (v.hasError) {
      _fail(AppStrings.videoUnavailable);
      return;
    }
    if (v.isReady) _maybeAutoPlay();

    switch (v.playerState) {
      case PlayerState.playing:
        if (_phase == WatchPhase.ready || _phase == WatchPhase.paused) {
          _phase = WatchPhase.playing;
          WakelockPlus.enable();
          notify();
        } else if (_phase != WatchPhase.playing) {
          // Playing while we are not expecting it (e.g. interrupted): stop.
          controller.pause();
        }
      case PlayerState.paused:
        if (_phase == WatchPhase.playing) {
          _phase = WatchPhase.paused;
          WakelockPlus.disable();
          notify();
        }
      case PlayerState.ended:
        if (_phase == WatchPhase.playing || _phase == WatchPhase.paused) _onEnded();
      default:
        break;
    }
  }

  void _tick() {
    if (isDisposed || _phase != WatchPhase.playing || !_foreground) return;
    final v = controller.value;
    if (v.playerState != PlayerState.playing) return;

    _watched++;

    if (v.playbackRate != 1.0) controller.setPlaybackRate(1.0);

    final drift = (v.position.inSeconds - _watched).abs();
    if (drift > AppConstants.seekToleranceSeconds) {
      _interrupt(AppStrings.seekDetectedTitle, AppStrings.seekDetectedMessage);
      return;
    }

    if (_sessionExpired) {
      _interrupt(AppStrings.leftAppTitle, AppStrings.sessionExpired);
      return;
    }

    final askAt = _stillWatchingAt;
    if (askAt != null && !_stillWatchingAsked && _watched >= askAt) {
      _stillWatchingAsked = true;
      controller.pause();
      _phase = WatchPhase.stillWatching;
    }
    notify();
  }

  bool get _sessionExpired {
    final start = _sessionStartedLocal;
    if (start == null) return false;
    final limit = task.durationSeconds * AppConstants.maxSessionDurationFactor;
    return DateTime.now().difference(start).inSeconds > limit;
  }

  /// Answer to the "Are you still watching?" prompt.
  void answerStillWatching(bool watching) {
    if (_phase != WatchPhase.stillWatching) return;
    if (watching) {
      _phase = WatchPhase.paused;
      notify();
      controller.play();
    } else {
      _interrupt(AppStrings.stillWatchingTitle, AppStrings.stillWatchingFailed);
    }
  }

  void _interrupt(String title, String message) {
    controller.pause();
    WakelockPlus.disable();
    _watched = 0;
    _phase = WatchPhase.interrupted;
    _interruptTitle = title;
    _interruptMessage = message;
    notify();
  }

  void _fail(String message) {
    controller.pause();
    WakelockPlus.disable();
    _phase = WatchPhase.failed;
    _interruptMessage = message;
    notify();
  }

  // ---------------------------------------------------------------- completion

  Future<void> _onEnded() async {
    WakelockPlus.disable();
    if (_watched < requiredSeconds) {
      _interrupt(AppStrings.leftAppTitle, AppStrings.notWatchedEnough);
      return;
    }
    _phase = WatchPhase.completing;
    notify();
    try {
      _earned = await _repo.completeTask(
        uid: _uid,
        task: task,
        reward: _settings.videoReward,
        watchedSeconds: _watched,
      );
      _tasks.markCompleted(task.id);
      _phase = WatchPhase.completed;
      notify();
    } catch (e) {
      debugPrint('Completion failed: $e');
      final error = AppException.from(e);
      if (error.message == AppStrings.alreadyCompleted) {
        _tasks.markCompleted(task.id);
        _fail(AppStrings.alreadyCompleted);
      } else if (error.code == 'permission-denied') {
        // Rules rejected the timing (or subscription/task changed meanwhile).
        _interrupt(AppStrings.leftAppTitle, _sessionExpired ? AppStrings.sessionExpired : AppStrings.notWatchedEnough);
      } else {
        _fail(error.message);
      }
    }
  }

  // ---------------------------------------------------------------- lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        if (_pausedForInactive && _phase == WatchPhase.paused) controller.play();
        _pausedForInactive = false;
        _maybeAutoPlay();
      case AppLifecycleState.inactive:
        _foreground = false;
        if (_phase == WatchPhase.playing) {
          _pausedForInactive = true;
          controller.pause();
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _pausedForInactive = false;
        final inProgress =
            _watched > 0 &&
            (_phase == WatchPhase.playing || _phase == WatchPhase.paused || _phase == WatchPhase.stillWatching);
        if (inProgress) _interrupt(AppStrings.leftAppTitle, AppStrings.leftAppMessage);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onPlayer);
    controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}
