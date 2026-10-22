import '../../data/models/order_status.dart';
import '../../data/models/withdraw_request.dart';
import '../../data/repositories/withdraw_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';

class AdminWithdrawalsViewModel extends BaseViewModel {
  AdminWithdrawalsViewModel({required WithdrawRepository repo, required String adminUid})
    : _repo = repo,
      _adminUid = adminUid {
    for (final s in OrderStatus.values) {
      lists[s] = PagedList<WithdrawRequest>((c) => _repo.pageByStatus(s, startAfter: c), notify);
    }
  }

  final WithdrawRepository _repo;
  final String _adminUid;
  final Map<OrderStatus, PagedList<WithdrawRequest>> lists = {};
  final Set<String> _busy = {};

  bool isBusy(String id) => _busy.contains(id);

  Future<bool> approve(WithdrawRequest r, {String? transferRef}) => _review(
    r,
    OrderStatus.approved,
    () => _repo.approve(requestId: r.id, adminUid: _adminUid, transferRef: transferRef),
  );

  Future<bool> reject(WithdrawRequest r, String reason) =>
      _review(r, OrderStatus.rejected, () => _repo.reject(requestId: r.id, adminUid: _adminUid, reason: reason));

  Future<bool> _review(WithdrawRequest r, OrderStatus target, Future<void> Function() action) async {
    _busy.add(r.id);
    notify();
    final ok = await runAction(action, showLoading: false);
    _busy.remove(r.id);
    lists[OrderStatus.pending]!.remove((x) => x.id == r.id);
    lists[target]!.invalidate();
    if (!ok) lists[OrderStatus.pending]!.refresh();
    notify();
    return ok;
  }
}
