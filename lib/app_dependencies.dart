import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/repositories/admin_user_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/promote_repository.dart';
import 'data/repositories/proof_repository.dart';
import 'data/repositories/referral_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/watch_repository.dart';
import 'data/repositories/withdraw_repository.dart';

/// Every repository the app uses. Production uses [AppDependencies.firebase];
/// widget tests pass fakes.
class AppDependencies {
  const AppDependencies({
    required this.proofs,
    required this.referrals,
    required this.auth,
    required this.users,
    required this.settings,
    required this.tasks,
    required this.watch,
    required this.wallet,
    required this.subscriptions,
    required this.withdrawals,
    required this.promote,
    required this.stats,
    required this.adminUsers,
  });

  factory AppDependencies.firebase() {
    final db = FirebaseFirestore.instance;
    final proofs = FirestoreProofRepository(db);
    final referrals = FirestoreReferralRepository(db);
    return AppDependencies(
      proofs: proofs,
      referrals: referrals,
      auth: FirebaseAuthRepository(auth: FirebaseAuth.instance, db: db, referrals: referrals),
      users: FirestoreUserRepository(db),
      settings: FirestoreSettingsRepository(db),
      tasks: FirestoreTaskRepository(db),
      watch: FirestoreWatchRepository(db),
      wallet: FirestoreWalletRepository(db),
      subscriptions: FirestoreSubscriptionRepository(db, proofs),
      withdrawals: FirestoreWithdrawRepository(db),
      promote: FirestorePromoteRepository(db, proofs),
      stats: FirestoreStatsRepository(db),
      adminUsers: FirestoreAdminUserRepository(db),
    );
  }

  final ProofRepository proofs;
  final ReferralRepository referrals;
  final AuthRepository auth;
  final UserRepository users;
  final SettingsRepository settings;
  final TaskRepository tasks;
  final WatchRepository watch;
  final WalletRepository wallet;
  final SubscriptionRepository subscriptions;
  final WithdrawRepository withdrawals;
  final PromoteRepository promote;
  final StatsRepository stats;
  final AdminUserRepository adminUsers;
}
