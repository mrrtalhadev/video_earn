import '../../data/models/video_task.dart';
import '../../data/repositories/task_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';

class AdminTasksViewModel extends BaseViewModel {
  AdminTasksViewModel(this._repo) {
    for (final f in AdminTaskFilter.values) {
      _lists[f] = PagedList<VideoTask>((cursor) => _repo.fetchAdminPage(f, startAfter: cursor), notify);
    }
    current.ensureLoaded();
  }

  final TaskRepository _repo;
  final Map<AdminTaskFilter, PagedList<VideoTask>> _lists = {};
  AdminTaskFilter _filter = AdminTaskFilter.all;

  AdminTaskFilter get filter => _filter;
  PagedList<VideoTask> get current => _lists[_filter]!;

  void setFilter(AdminTaskFilter f) {
    if (f == _filter) return;
    _filter = f;
    notify();
    current.ensureLoaded();
  }

  /// Call after a task was created/edited elsewhere.
  Future<void> refreshAll() async {
    for (final l in _lists.values) {
      l.invalidate();
    }
    await current.refresh();
  }

  Future<bool> delete(String id) async {
    final ok = await runAction(() => _repo.deleteTask(id));
    if (ok) {
      for (final l in _lists.values) {
        l.remove((t) => t.id == id);
      }
    }
    return ok;
  }

  Future<int?> countExpired() => guard(_repo.countExpired, showLoading: false);

  Future<int?> purgeExpired() async {
    final n = await guard(_repo.purgeExpired);
    if (n != null) await refreshAll();
    return n;
  }
}
