import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/order_status.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.depositedToday,
    required this.depositedLifetime,
    required this.withdrawnToday,
    required this.withdrawnLifetime,
    required this.promoteDeposits,
    required this.pendingWithdrawAmount,
    required this.pendingSubscriptions,
    required this.pendingWithdrawals,
    required this.pendingPromotions,
    required this.fetchedAt,
  });

  final int totalUsers;
  final int activeUsers;
  final int depositedToday;
  final int depositedLifetime;
  final int withdrawnToday;
  final int withdrawnLifetime;
  final int promoteDeposits;
  final int pendingWithdrawAmount;
  final int pendingSubscriptions;
  final int pendingWithdrawals;
  final int pendingPromotions;
  final DateTime fetchedAt;
}

abstract class StatsRepository {
  /// All numbers come from aggregation queries (count/sum), so they can never
  /// drift from the underlying documents. ~11 aggregation reads per refresh.
  Future<DashboardStats> fetchDashboard();
}

class FirestoreStatsRepository implements StatsRepository {
  FirestoreStatsRepository(this._db);

  final FirebaseFirestore _db;

  Future<int> _count(Query<Map<String, dynamic>> q) async => (await q.count().get()).count ?? 0;

  Future<int> _sum(Query<Map<String, dynamic>> q, String field) async {
    final snap = await q.aggregate(sum(field)).get();
    return (snap.getSum(field) ?? 0).round();
  }

  Future<(int, int)> _countAndSum(Query<Map<String, dynamic>> q, String field) async {
    final snap = await q.aggregate(count(), sum(field)).get();
    return (snap.count ?? 0, (snap.getSum(field) ?? 0).round());
  }

  @override
  Future<DashboardStats> fetchDashboard() async {
    final today = Timestamp.fromDate(AppDateUtils.startOfKarachiDay());
    final approved = OrderStatus.approved.name;
    final pending = OrderStatus.pending.name;

    final users = _db.collection(FsCol.users);
    final subs = _db.collection(FsCol.subscriptionOrders);
    final promos = _db.collection(FsCol.promoteOrders);
    final withdraws = _db.collection(FsCol.withdrawRequests);

    final subsApproved = subs.where(FsKeys.status, isEqualTo: approved);
    final promosApproved = promos.where(FsKeys.status, isEqualTo: approved);
    final withdrawsApproved = withdraws.where(FsKeys.status, isEqualTo: approved);

    final results = await Future.wait<Object>([
      _count(users), // 0
      _count(users.where(FsKeys.subscriptionActive, isEqualTo: true)), // 1
      _sum(subsApproved, FsKeys.amount), // 2
      _sum(subsApproved.where(FsKeys.reviewedAt, isGreaterThanOrEqualTo: today), FsKeys.amount), // 3
      _sum(promosApproved, FsKeys.price), // 4
      _sum(promosApproved.where(FsKeys.reviewedAt, isGreaterThanOrEqualTo: today), FsKeys.price), // 5
      _sum(withdrawsApproved, FsKeys.amount), // 6
      _sum(withdrawsApproved.where(FsKeys.reviewedAt, isGreaterThanOrEqualTo: today), FsKeys.amount), // 7
      _countAndSum(withdraws.where(FsKeys.status, isEqualTo: pending), FsKeys.amount), // 8
      _count(subs.where(FsKeys.status, isEqualTo: pending)), // 9
      _count(promos.where(FsKeys.status, isEqualTo: pending)), // 10
    ]);

    final pendingWithdraw = results[8] as (int, int);
    return DashboardStats(
      totalUsers: results[0] as int,
      activeUsers: results[1] as int,
      depositedLifetime: (results[2] as int) + (results[4] as int),
      depositedToday: (results[3] as int) + (results[5] as int),
      promoteDeposits: results[4] as int,
      withdrawnLifetime: results[6] as int,
      withdrawnToday: results[7] as int,
      pendingWithdrawals: pendingWithdraw.$1,
      pendingWithdrawAmount: pendingWithdraw.$2,
      pendingSubscriptions: results[9] as int,
      pendingPromotions: results[10] as int,
      fetchedAt: DateTime.now(),
    );
  }
}
