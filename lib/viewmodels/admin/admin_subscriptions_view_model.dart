import '../../data/models/order_status.dart';
import '../../data/models/subscription_order.dart';
import '../../data/repositories/promote_repository.dart';
import '../../data/repositories/proof_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';
import 'review_support.dart';

class AdminSubscriptionsViewModel extends BaseViewModel with ReviewSupport {
  AdminSubscriptionsViewModel({
    required this.subscriptionRepo,
    required this.promoteRepo,
    required this.proofRepo,
    required String adminUid,
  }) : _adminUid = adminUid {
    for (final s in OrderStatus.values) {
      lists[s] = PagedList<SubscriptionOrder>((cursor) => subscriptionRepo.pageByStatus(s, startAfter: cursor), notify);
    }
  }

  @override
  final SubscriptionRepository subscriptionRepo;
  @override
  final PromoteRepository promoteRepo;
  @override
  final ProofRepository proofRepo;
  final String _adminUid;

  final Map<OrderStatus, PagedList<SubscriptionOrder>> lists = {};

  Future<bool> approve(SubscriptionOrder order) async {
    final ok = await review(order.id, () => subscriptionRepo.approve(orderId: order.id, adminUid: _adminUid));
    _afterReview(order, ok, OrderStatus.approved);
    return ok;
  }

  Future<bool> reject(SubscriptionOrder order, String reason) async {
    final ok = await review(
      order.id,
      () => subscriptionRepo.reject(orderId: order.id, adminUid: _adminUid, reason: reason),
    );
    _afterReview(order, ok, OrderStatus.rejected);
    return ok;
  }

  /// On success (or "already reviewed" elsewhere) the order leaves Pending.
  void _afterReview(SubscriptionOrder order, bool ok, OrderStatus target) {
    lists[OrderStatus.pending]!.remove((o) => o.id == order.id);
    lists[target]!.invalidate();
    if (!ok) lists[OrderStatus.pending]!.refresh();
  }
}
