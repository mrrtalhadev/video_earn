import '../../core/utils/youtube_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/video_task.dart';
import '../../data/models/video_verify_result.dart';
import '../../data/repositories/task_repository.dart';
import '../base_view_model.dart';

/// Add/Edit task. Save is only enabled once the video was loaded & verified
/// (or, when editing, the link is unchanged from the already-verified task).
class TaskEditViewModel extends BaseViewModel {
  TaskEditViewModel(this._repo, {this.existing}) : _videoId = existing?.youtubeVideoId;

  final TaskRepository _repo;
  final VideoTask? existing;

  String? _videoId;
  VideoVerifyResult? _verified;

  String? get videoId => _videoId;
  VideoVerifyResult? get verified => _verified;

  bool get isPromoted => existing?.source == TaskSource.promote;

  bool get _unchangedExisting => existing != null && _videoId == existing!.youtubeVideoId;

  bool get canSave => _videoId != null && (_verified != null || _unchangedExisting);

  int? get durationSeconds => _verified?.durationSeconds ?? (_unchangedExisting ? existing!.durationSeconds : null);

  void onUrlChanged(String url) {
    final id = YoutubeUtils.extractVideoId(url);
    if (id == _videoId) return;
    _videoId = id;
    _verified = null;
    notify();
  }

  void onVerified(VideoVerifyResult? result) {
    _verified = result;
    notify();
  }

  Future<bool> save({required String title, required String description, required bool isActive, required int order}) {
    // Promoted tasks keep their owner, video and run period; only the
    // presentation fields are editable.
    if (isPromoted) {
      return runAction(
        () => _repo.updateTask(existing!.id, {
          FsKeys.title: title.trim(),
          FsKeys.description: description.trim(),
          FsKeys.isActive: isActive,
          FsKeys.order: order,
        }),
      );
    }
    final data = VideoTask.adminMap(
      title: title.trim(),
      description: description.trim(),
      videoId: _videoId!,
      durationSeconds: durationSeconds!,
      isActive: isActive,
      order: order,
    );
    return runAction(() => existing == null ? _repo.createTask(data) : _repo.updateTask(existing!.id, data));
  }
}
