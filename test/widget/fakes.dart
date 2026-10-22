import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_earn/app_dependencies.dart';
import 'package:video_earn/data/models/app_settings.dart';
import 'package:video_earn/data/models/app_user.dart';
import 'package:video_earn/data/models/faq_item.dart';
import 'package:video_earn/data/models/order_status.dart';
import 'package:video_earn/data/models/promote_order.dart';
import 'package:video_earn/data/models/promote_package.dart';
import 'package:video_earn/data/models/referral_entry.dart';
import 'package:video_earn/data/models/subscription_order.dart';
import 'package:video_earn/data/models/video_task.dart';
import 'package:video_earn/data/models/wallet_transaction.dart';
import 'package:video_earn/data/models/withdraw_request.dart';
import 'package:video_earn/data/repositories/admin_user_repository.dart';
import 'package:video_earn/data/repositories/auth_repository.dart';
import 'package:video_earn/data/repositories/page_result.dart';
import 'package:video_earn/data/repositories/promote_repository.dart';
import 'package:video_earn/data/repositories/proof_repository.dart';
import 'package:video_earn/data/repositories/referral_repository.dart';
import 'package:video_earn/data/repositories/settings_repository.dart';
import 'package:video_earn/data/repositories/stats_repository.dart';
import 'package:video_earn/data/repositories/subscription_repository.dart';
import 'package:video_earn/data/repositories/task_repository.dart';
import 'package:video_earn/data/repositories/user_repository.dart';
import 'package:video_earn/data/repositories/wallet_repository.dart';
import 'package:video_earn/data/repositories/watch_repository.dart';
import 'package:video_earn/data/repositories/withdraw_repository.dart';

final _now = DateTime.utc(2026, 10, 1, 12);

const settings = AppSettings(
  bank: BankDetails(
    bankName: 'Habib Bank Limited',
    accountTitle: 'TaskEarn Private Limited',
    accountNumber: '12345678901234',
    iban: 'PK36SCBL0000001123456702',
  ),
  supportWhatsapp: '923001234567',
  supportEmail: 'support@example.com',
  aboutUs: 'About text',
  termsAndConditions: 'Terms text',
  contactUs: ContactInfo(phone: '03001234567', email: 'hello@example.com', address: 'Lahore'),
);

AppUser sampleUser({bool subscribed = true, bool pending = false, int balance = 2450}) => AppUser(
  uid: 'u1',
  name: 'Muhammad Abdullah Khan',
  email: 'abdullah.khan.longemail@example.com',
  phone: '03001234567',
  subscriptionActive: subscribed,
  hasPendingSubscription: pending,
  balance: balance,
  totalEarned: 125000,
  totalReferralEarned: 900,
  totalWithdrawn: 1500000,
  pendingWithdraw: 1500,
  completedTasksCount: 1234,
  referralCode: 'AB12CD34',
  referralCount: 3,
  createdAt: _now,
);

VideoTask sampleTask(int i, {TaskSource source = TaskSource.admin}) => VideoTask(
  id: 't$i',
  title: 'A fairly long video title number $i that should wrap onto two lines nicely',
  description: 'Description',
  youtubeVideoId: 'dQw4w9WgXcQ',
  youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  thumbnailUrl: '',
  durationSeconds: 212,
  source: source,
  isActive: true,
  expiresAt: DateTime.utc(2099, 12, 31),
  createdAt: _now,
);

class FakeUser implements User {
  FakeUser(this.uid);

  @override
  final String uid;

  @override
  String? get email => 'abdullah.khan.longemail@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedIn = true, this.admin = false});

  final bool signedIn;
  final bool admin;
  late final User? _user = signedIn ? FakeUser('u1') : null;

  @override
  Stream<User?> authStateChanges() => Stream.value(_user);
  @override
  User? get currentUser => _user;
  @override
  Future<bool> isAdmin(String uid) async => admin;
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {}
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async {}
}

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.user);

  final AppUser user;

  @override
  Stream<AppUser?> watchUser(String uid) => Stream.value(user);
  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? photoUrl,
  }) async {}
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  Stream<AppSettings?> watchSettings() => Stream.value(settings);
  @override
  Future<AppSettings?> fetchSettings() async => settings;
  @override
  Future<void> saveSettings(AppSettings s) async {}
  @override
  Future<void> createDefaults() async {}
  @override
  Future<List<FaqItem>> fetchFaqs({bool activeOnly = true}) async => [
    const FaqItem(id: 'f1', question: 'How do I earn?', answer: 'Watch videos fully.'),
  ];
  @override
  Future<void> saveFaq(FaqItem faq) async {}
  @override
  Future<void> deleteFaq(String id) async {}
}

PageResult<T> _page<T>(List<T> items) => PageResult(items: items, cursor: null, hasMore: false);

class FakeTaskRepository implements TaskRepository {
  @override
  Future<List<VideoTask>> fetchVisibleTasks() async => List.generate(6, sampleTask);
  @override
  Future<Set<String>> fetchCompletedTaskIds(String uid) async => {'t1'};
  @override
  Future<PageResult<VideoTask>> fetchAdminPage(AdminTaskFilter filter, {JsonDoc? startAfter}) async =>
      _page([sampleTask(1), sampleTask(2, source: TaskSource.promote)]);
  @override
  Future<void> createTask(Map<String, dynamic> data) async {}
  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<int> countExpired() async => 0;
  @override
  Future<int> purgeExpired() async => 0;
}

class FakeWatchRepository implements WatchRepository {
  @override
  Future<void> startSession({required String uid, required String taskId}) async {}
  @override
  Future<int> completeTask({
    required String uid,
    required VideoTask task,
    required int reward,
    required int watchedSeconds,
  }) async => reward;
}

final _txs = [
  WalletTransaction(
    id: 'a',
    type: TxType.taskReward,
    amount: 10,
    balanceAfter: 2450,
    refId: 't1',
    title: 'Some long video title',
    createdAt: _now,
  ),
  WalletTransaction(
    id: 'b',
    type: TxType.withdrawHold,
    amount: -1500,
    balanceAfter: 2440,
    refId: 'w1',
    title: '',
    createdAt: _now,
  ),
  WalletTransaction(
    id: 'c',
    type: TxType.referralBonus,
    amount: 300,
    balanceAfter: 3940,
    refId: 'u2',
    title: '',
    createdAt: _now,
  ),
];

class FakeWalletRepository implements WalletRepository {
  @override
  Future<List<WalletTransaction>> recent(String uid, {int limit = 10}) async => _txs;
  @override
  Future<PageResult<WalletTransaction>> page(String uid, {List<TxType>? types, JsonDoc? startAfter}) async =>
      _page(_txs);
}

SubscriptionOrder _subOrder(OrderStatus s) => SubscriptionOrder(
  id: 'o${s.name}',
  uid: 'u1',
  userName: 'Muhammad Abdullah Khan',
  userEmail: 'abdullah.khan.longemail@example.com',
  amount: 1500,
  priceAtSubmission: 1500,
  transactionId: 'TXN1234567890',
  proofId: 'o1',
  status: s,
  rejectionReason: s == OrderStatus.rejected ? 'No matching transfer found' : null,
  createdAt: _now,
  reviewedAt: s == OrderStatus.pending ? null : _now,
);

class FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<void> submit({
    required AppUser user,
    required int expectedPrice,
    required String transactionId,
    required Uint8List proofBytes,
  }) async {}
  @override
  Stream<SubscriptionOrder?> watchLatestOrder(String uid) => Stream.value(null);
  @override
  Future<List<SubscriptionOrder>> ordersForUser(String uid) async => [_subOrder(OrderStatus.approved)];
  @override
  Future<PageResult<SubscriptionOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) async =>
      _page([_subOrder(status)]);
  @override
  Future<int> countSameTransactionId(String transactionId) async => 2;
  @override
  Future<void> approve({required String orderId, required String adminUid}) async {}
  @override
  Future<void> reject({required String orderId, required String adminUid, required String reason}) async {}
}

WithdrawRequest _withdraw(OrderStatus s) => WithdrawRequest(
  id: 'w${s.name}',
  uid: 'u1',
  userName: 'Muhammad Abdullah Khan',
  amount: 150000,
  accountHolderName: 'Muhammad Abdullah Khan',
  bankName: 'Habib Bank Limited',
  accountNumber: 'PK36SCBL0000001123456702',
  status: s,
  createdAt: _now,
);

class FakeWithdrawRepository implements WithdrawRepository {
  @override
  Future<void> submit({
    required String uid,
    required int amount,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
  }) async {}
  @override
  Future<PageResult<WithdrawRequest>> pageForUser(String uid, {JsonDoc? startAfter}) async =>
      _page([_withdraw(OrderStatus.pending)]);
  @override
  Future<PageResult<WithdrawRequest>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) async =>
      _page([_withdraw(status)]);
  @override
  Future<void> approve({required String requestId, required String adminUid, String? transferRef}) async {}
  @override
  Future<void> reject({required String requestId, required String adminUid, required String reason}) async {}
}

PromoteOrder _promo(OrderStatus s) => PromoteOrder(
  id: 'p${s.name}',
  uid: 'u1',
  userName: 'Muhammad Abdullah Khan',
  videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  youtubeVideoId: 'dQw4w9WgXcQ',
  videoTitle: 'My channel trailer with a long descriptive title',
  videoDescription: 'Desc',
  packageId: 'pk1',
  packageName: '3 Days',
  price: 1500,
  durationDays: 3,
  transactionId: 'TXN99999999',
  proofId: 'p1',
  status: s,
  createdAt: _now,
  startAt: s == OrderStatus.approved ? _now : null,
  expiresAt: s == OrderStatus.approved ? _now.add(const Duration(days: 3)) : null,
);

class FakePromoteRepository implements PromoteRepository {
  @override
  Future<List<PromotePackage>> fetchPackages({bool activeOnly = true}) async => const [
    PromotePackage(id: 'pk1', name: '1 Day', price: 500, durationDays: 1, isActive: true),
    PromotePackage(id: 'pk2', name: '3 Days', price: 1500, durationDays: 3, isActive: false, description: 'Best value'),
  ];
  @override
  Future<void> savePackage(PromotePackage package) async {}
  @override
  Future<bool> deleteOrDeactivatePackage(String id) async => true;
  @override
  Future<void> submitOrder({
    required String uid,
    required PromotePackage package,
    required String videoUrl,
    required String videoId,
    required String title,
    required String description,
    required String transactionId,
    required Uint8List proofBytes,
  }) async {}
  @override
  Future<PageResult<PromoteOrder>> pageForUser(String uid, {JsonDoc? startAfter}) async =>
      _page([_promo(OrderStatus.approved), _promo(OrderStatus.rejected)]);
  @override
  Future<PageResult<PromoteOrder>> pageByStatus(OrderStatus status, {JsonDoc? startAfter}) async =>
      _page([_promo(status)]);
  @override
  Future<int> countSameTransactionId(String transactionId) async => 1;
  @override
  Future<void> approve({required String orderId, required String adminUid, required int durationSeconds}) async {}
  @override
  Future<void> reject({required String orderId, required String adminUid, required String reason}) async {}
}

class FakeReferralRepository implements ReferralRepository {
  @override
  Future<String?> ownerOfCode(String code) async => null;
  @override
  Future<List<ReferralEntry>> referredBy(String uid) async => [
    ReferralEntry(refereeUid: 'a', refereeName: 'Ayesha Siddiqui', bonusPaid: true, bonus: 300, createdAt: _now),
    ReferralEntry(refereeUid: 'b', refereeName: 'Bilal', bonusPaid: false, bonus: 0, createdAt: _now),
  ];
}

class FakeStatsRepository implements StatsRepository {
  @override
  Future<DashboardStats> fetchDashboard() async => DashboardStats(
    totalUsers: 125430,
    activeUsers: 98000,
    depositedToday: 1500000,
    depositedLifetime: 987654321,
    withdrawnToday: 450000,
    withdrawnLifetime: 123456789,
    promoteDeposits: 4500000,
    pendingWithdrawAmount: 3000000,
    pendingSubscriptions: 12,
    pendingWithdrawals: 4,
    pendingPromotions: 0,
    fetchedAt: _now,
  );
}

class FakeAdminUserRepository implements AdminUserRepository {
  @override
  Future<PageResult<AppUser>> fetchUsers({
    UserFilter filter = UserFilter.all,
    String search = '',
    JsonDoc? startAfter,
  }) async => _page([sampleUser(), sampleUser(subscribed: false)]);
  @override
  Stream<AppUser?> watchUser(String uid) => Stream.value(sampleUser());
  @override
  Future<void> setBlocked(String uid, bool blocked) async {}
}

class FakeProofRepository implements ProofRepository {
  @override
  void attach(Transaction tx, {required String orderId, required String uid, required Uint8List bytes}) {}
  @override
  Future<Uint8List?> load(String proofId) async => null;
}

AppDependencies fakeDependencies({bool signedIn = true, bool admin = false, AppUser? user}) => AppDependencies(
  proofs: FakeProofRepository(),
  referrals: FakeReferralRepository(),
  auth: FakeAuthRepository(signedIn: signedIn, admin: admin),
  users: FakeUserRepository(user ?? sampleUser()),
  settings: FakeSettingsRepository(),
  tasks: FakeTaskRepository(),
  watch: FakeWatchRepository(),
  wallet: FakeWalletRepository(),
  subscriptions: FakeSubscriptionRepository(),
  withdrawals: FakeWithdrawRepository(),
  promote: FakePromoteRepository(),
  stats: FakeStatsRepository(),
  adminUsers: FakeAdminUserRepository(),
);
