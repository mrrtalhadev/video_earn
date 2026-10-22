import '../../data/models/order_status.dart';
import '../../data/models/promote_order.dart';
import '../../data/models/video_verify_result.dart';
import '../../data/repositories/promote_repository.dart';
import '../../data/repositories/proof_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';
import 'review_support.dart';

class AdminPromoteOrdersViewModel extends BaseViewModel with ReviewSupport {
  AdminPromoteOrdersViewModel({
    required this.promoteRepo,
    required this.subscriptionRepo,
    required this.proofRepo,
    required String adminUid,
  }) : _adminUid = adminUid {
    for (final s in OrderStatus.values) {
      lists[s] = PagedList<PromoteOrder>((c) => promoteRepo.pageByStatus(s, startAfter: c), notify);
    }
  }

  @override
  final PromoteRepository promoteRepo;
  @override
  final SubscriptionRepository subscriptionRepo;
  @override
  final ProofRepository proofRepo;
  final String _adminUid;

  final Map<OrderStatus, PagedList<PromoteOrder>> lists = {};
  final Map<String, VideoVerifyResult> _verified = {};

  VideoVerifyResult? verifiedFor(String orderId) => _verified[orderId];

  void setVerified(String orderId, VideoVerifyResult? result) {
    if (result == null) {
      _verified.remove(orderId);
    } else {
      _verified[orderId] = result;
    }
    notify();
  }

  /// Approval requires a successful "Load & verify" of the video first.
  Future<bool> approve(PromoteOrder order) async {
    final verified = _verified[order.id];
    if (verified == null) return false;
    final ok = await review(
      order.id,
      () => promoteRepo.approve(orderId: order.id, adminUid: _adminUid, durationSeconds: verified.durationSeconds),
    );
    _after(order, ok, OrderStatus.approved);
    return ok;
  }

  Future<bool> reject(PromoteOrder order, String reason) async {
    final ok = await review(order.id, () => promoteRepo.reject(orderId: order.id, adminUid: _adminUid, reason: reason));
    _after(order, ok, OrderStatus.rejected);
    return ok;
  }

  void _after(PromoteOrder order, bool ok, OrderStatus target) {
    _verified.remove(order.id);
    lists[OrderStatus.pending]!.remove((o) => o.id == order.id);
    lists[target]!.invalidate();
    if (!ok) lists[OrderStatus.pending]!.refresh();
  }
}
