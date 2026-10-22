import '../../data/models/promote_order.dart';
import '../../data/repositories/promote_repository.dart';
import '../base_view_model.dart';
import '../paged_list.dart';

class MyPromoteOrdersViewModel extends BaseViewModel {
  MyPromoteOrdersViewModel(PromoteRepository repo, String uid) {
    orders = PagedList<PromoteOrder>((c) => repo.pageForUser(uid, startAfter: c), notify)..refresh();
  }

  late final PagedList<PromoteOrder> orders;
}
