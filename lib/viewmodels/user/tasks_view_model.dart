import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/video_task.dart';
import '../../data/repositories/task_repository.dart';
import '../base_view_model.dart';

enum TaskFilter { all, pending, completed }

/// Visible tasks + the user's completed ids, shared by Home, See All and the
/// player (app-level, rebuilt per signed-in uid via ChangeNotifierProxyProvider).
class TasksViewModel extends BaseViewModel {
  TasksViewModel(this._repo);

  final TaskRepository _repo;

  String? _uid;
  List<VideoTask> _tasks = const [];
  Set<String> _completed = {};
  bool _loaded = false;
  TaskFilter _filter = TaskFilter.all;
  int _visibleCount = AppConstants.pageSize;

  List<VideoTask> get tasks => _tasks;
  bool get loaded => _loaded;
  TaskFilter get filter => _filter;

  bool isCompleted(String taskId) => _completed.contains(taskId);

  List<VideoTask> get preview => _tasks.take(AppConstants.homeTasksPreview).toList();

  List<VideoTask> get _filtered => switch (_filter) {
    TaskFilter.all => _tasks,
    TaskFilter.pending => _tasks.where((t) => !isCompleted(t.id)).toList(),
    TaskFilter.completed => _tasks.where((t) => isCompleted(t.id)).toList(),
  };

  /// Local pagination over the ≤100 loaded tasks (20 per page).
  List<VideoTask> get page => _filtered.take(_visibleCount).toList();
  bool get hasMorePages => _filtered.length > _visibleCount;

  /// Called by the proxy provider whenever the session changes (during
  /// build), so it resets silently and notifies after the frame.
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _tasks = const [];
    _completed = {};
    _loaded = false;
    _filter = TaskFilter.all;
    _visibleCount = AppConstants.pageSize;
    Future.microtask(() => setState(ViewState.idle));
  }

  Future<void> ensureLoaded() async {
    if (!_loaded && !isLoading) await load();
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    setState(ViewState.loading);
    try {
      final results = await Future.wait([_repo.fetchVisibleTasks(), _repo.fetchCompletedTaskIds(uid)]);
      if (uid != _uid) return;
      _tasks = results[0] as List<VideoTask>;
      _completed = results[1] as Set<String>;
      _loaded = true;
      setState(ViewState.success);
    } catch (e) {
      debugPrint('Load tasks failed: $e');
      if (uid == _uid) setState(ViewState.error, error: AppException.from(e).message);
    }
  }

  void setFilter(TaskFilter f) {
    if (f == _filter) return;
    _filter = f;
    _visibleCount = AppConstants.pageSize;
    notify();
  }

  void showMore() {
    _visibleCount += AppConstants.pageSize;
    notify();
  }

  void markCompleted(String taskId) {
    _completed = {..._completed, taskId};
    notify();
  }
}
