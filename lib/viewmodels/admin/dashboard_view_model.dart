import '../../data/repositories/stats_repository.dart';
import '../base_view_model.dart';

/// Dashboard numbers from aggregation queries, cached until pull-to-refresh
/// to stay well inside the free-tier read quota.
class DashboardViewModel extends BaseViewModel {
  DashboardViewModel(this._repo) {
    refresh();
  }

  final StatsRepository _repo;
  DashboardStats? _stats;

  DashboardStats? get stats => _stats;

  Future<void> refresh() async {
    final result = await guard(_repo.fetchDashboard);
    if (result != null) {
      _stats = result;
      notify();
    }
  }
}
