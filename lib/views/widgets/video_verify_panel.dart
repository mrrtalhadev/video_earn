import 'dart:async';

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_verify_result.dart';

enum _VerifyStatus { idle, loading, ok, error }

/// "Load & verify": loads the video in an embedded preview player and reads
/// its real duration from the player metadata. Rejects videos that cannot be
/// embedded (errors 101/150), live streams and videos longer than
/// [maxMinutes]. Calls [onResult] with the verified result (or null when the
/// verification is reset/failed).
class VideoVerifyPanel extends StatefulWidget {
  const VideoVerifyPanel({super.key, required this.videoId, required this.maxMinutes, required this.onResult});

  /// The parsed id from the URL field; null disables the button.
  final String? videoId;
  final int maxMinutes;
  final ValueChanged<VideoVerifyResult?> onResult;

  @override
  State<VideoVerifyPanel> createState() => _VideoVerifyPanelState();
}

class _VideoVerifyPanelState extends State<VideoVerifyPanel> {
  static const Duration _timeout = Duration(seconds: 25);
  static const Duration _liveDetect = Duration(seconds: 6);

  YoutubePlayerController? _controller;
  _VerifyStatus _status = _VerifyStatus.idle;
  String? _message;
  String? _verifiedId;
  Timer? _timeoutTimer;
  DateTime? _playingSince;

  @override
  void didUpdateWidget(covariant VideoVerifyPanel old) {
    super.didUpdateWidget(old);
    if (old.videoId != widget.videoId && _verifiedId != widget.videoId) _reset();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.removeListener(_onPlayer);
    _controller?.dispose();
    super.dispose();
  }

  void _reset() {
    _timeoutTimer?.cancel();
    _controller?.removeListener(_onPlayer);
    _controller?.dispose();
    _controller = null;
    _verifiedId = null;
    _playingSince = null;
    if (_status != _VerifyStatus.idle) {
      setState(() {
        _status = _VerifyStatus.idle;
        _message = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onResult(null));
    }
  }

  void _start() {
    final id = widget.videoId;
    if (id == null) return;
    _timeoutTimer?.cancel();
    _controller?.removeListener(_onPlayer);
    _controller?.dispose();
    _playingSince = null;
    widget.onResult(null);

    final controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: true, enableCaption: false),
    )..addListener(_onPlayer);
    setState(() {
      _controller = controller;
      _status = _VerifyStatus.loading;
      _message = AppStrings.verifying;
    });
    _timeoutTimer = Timer(_timeout, () => _fail(AppStrings.verifyTimeout));
  }

  void _onPlayer() {
    final c = _controller;
    if (c == null || _status != _VerifyStatus.loading) return;
    final v = c.value;

    if (v.hasError) {
      final notEmbeddable = v.errorCode == 101 || v.errorCode == 150;
      _fail(notEmbeddable ? AppStrings.verifyNotEmbeddable : AppStrings.verifyFailed);
      return;
    }

    final seconds = v.metaData.duration.inSeconds;
    if (seconds > 0) {
      if (seconds > widget.maxMinutes * 60) {
        _fail(AppStrings.verifyTooLong(widget.maxMinutes));
        return;
      }
      _succeed(VideoVerifyResult(durationSeconds: seconds, title: v.metaData.title));
      return;
    }

    // Live streams report no duration while playing.
    if (v.playerState == PlayerState.playing) {
      _playingSince ??= DateTime.now();
      if (DateTime.now().difference(_playingSince!) > _liveDetect) _fail(AppStrings.verifyLive);
    }
  }

  void _succeed(VideoVerifyResult result) {
    _timeoutTimer?.cancel();
    _controller?.pause();
    _verifiedId = widget.videoId;
    setState(() {
      _status = _VerifyStatus.ok;
      _message = '${AppStrings.verifiedOk} · ${AppStrings.verifiedDetail(Formatters.duration(result.durationSeconds))}';
    });
    widget.onResult(result);
  }

  void _fail(String message) {
    _timeoutTimer?.cancel();
    _controller?.pause();
    if (!mounted) return;
    setState(() {
      _status = _VerifyStatus.error;
      _message = message;
    });
    widget.onResult(null);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final (color, icon) = switch (_status) {
      _VerifyStatus.ok => (AppColors.success, Icons.verified_rounded),
      _VerifyStatus.error => (AppColors.error, Icons.error_rounded),
      _ => (AppColors.textSecondary, Icons.hourglass_top_rounded),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: widget.videoId == null || _status == _VerifyStatus.loading ? null : _start,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text(AppStrings.loadAndVerify),
        ),
        if (controller != null) ...[
          SizedBox(height: 1.5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.w),
            child: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.primary,
            ),
          ),
        ],
        if (_message != null) ...[
          SizedBox(height: 1.h),
          Row(
            children: [
              if (_status == _VerifyStatus.loading)
                SizedBox(width: 4.w, height: 4.w, child: const CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(icon, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(_message!, style: AppTextStyles.caption.copyWith(color: color)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
