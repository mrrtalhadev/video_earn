import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.isBlocked = false,
    this.subscriptionActive = false,
    this.subscriptionActivatedAt,
    this.hasPendingSubscription = false,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalReferralEarned = 0,
    this.totalWithdrawn = 0,
    this.pendingWithdraw = 0,
    this.completedTasksCount = 0,
    required this.referralCode,
    this.referredBy,
    this.referredByCode,
    this.referralBonusPaid = false,
    this.referralCount = 0,
    this.lastWithdrawAt,
    this.lastWithdrawRequestId,
    this.lastCompletionTaskId,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final bool isBlocked;
  final bool subscriptionActive;
  final DateTime? subscriptionActivatedAt;
  final bool hasPendingSubscription;
  final int balance;
  final int totalEarned;
  final int totalReferralEarned;
  final int totalWithdrawn;
  final int pendingWithdraw;
  final int completedTasksCount;
  final String referralCode;
  final String? referredBy;
  final String? referredByCode;
  final bool referralBonusPaid;
  final int referralCount;
  final DateTime? lastWithdrawAt;
  final String? lastWithdrawRequestId;
  final String? lastCompletionTaskId;
  final DateTime? createdAt;

  /// Subscribed and not blocked — same definition as `active()` in the rules.
  bool get canEarn => subscriptionActive && !isBlocked;

  String get firstName => name.trim().split(' ').first;

  factory AppUser.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      name: d.str(FsKeys.name),
      email: d.str(FsKeys.email),
      phone: d.str(FsKeys.phone),
      photoUrl: d.strOrNull(FsKeys.photoUrl),
      isBlocked: d.boolean(FsKeys.isBlocked),
      subscriptionActive: d.boolean(FsKeys.subscriptionActive),
      subscriptionActivatedAt: d.date(FsKeys.subscriptionActivatedAt),
      hasPendingSubscription: d.boolean(FsKeys.hasPendingSubscription),
      balance: d.integer(FsKeys.balance),
      totalEarned: d.integer(FsKeys.totalEarned),
      totalReferralEarned: d.integer(FsKeys.totalReferralEarned),
      totalWithdrawn: d.integer(FsKeys.totalWithdrawn),
      pendingWithdraw: d.integer(FsKeys.pendingWithdraw),
      completedTasksCount: d.integer(FsKeys.completedTasksCount),
      referralCode: d.str(FsKeys.referralCode),
      referredBy: d.strOrNull(FsKeys.referredBy),
      referredByCode: d.strOrNull(FsKeys.referredByCode),
      referralBonusPaid: d.boolean(FsKeys.referralBonusPaid),
      referralCount: d.integer(FsKeys.referralCount),
      lastWithdrawAt: d.date(FsKeys.lastWithdrawAt),
      lastWithdrawRequestId: d.strOrNull(FsKeys.lastWithdrawRequestId),
      lastCompletionTaskId: d.strOrNull(FsKeys.lastCompletionTaskId),
      createdAt: d.date(FsKeys.createdAt),
    );
  }

  /// Exact field set the `users` create rule expects at signup.
  static Map<String, dynamic> createMap({
    required String name,
    required String email,
    required String phone,
    required String referralCode,
    String? referredBy,
    String? referredByCode,
  }) => {
    FsKeys.name: name,
    FsKeys.nameLower: name.toLowerCase(),
    FsKeys.email: email,
    FsKeys.phone: phone,
    FsKeys.photoUrl: null,
    FsKeys.isBlocked: false,
    FsKeys.subscriptionActive: false,
    FsKeys.subscriptionActivatedAt: null,
    FsKeys.hasPendingSubscription: false,
    FsKeys.balance: 0,
    FsKeys.totalEarned: 0,
    FsKeys.totalReferralEarned: 0,
    FsKeys.totalWithdrawn: 0,
    FsKeys.pendingWithdraw: 0,
    FsKeys.completedTasksCount: 0,
    FsKeys.referralCode: referralCode,
    FsKeys.referredBy: referredBy,
    FsKeys.referredByCode: referredByCode,
    FsKeys.referralBonusPaid: false,
    FsKeys.referralCount: 0,
    FsKeys.lastWithdrawAt: null,
    FsKeys.lastWithdrawRequestId: null,
    FsKeys.lastCompletionTaskId: null,
    FsKeys.createdAt: FieldValue.serverTimestamp(),
  };
}
