import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../models/video_task.dart';
import '../models/wallet_transaction.dart';
import '../models/watch_session.dart';
import 'page_result.dart';

abstract class WatchRepository {
  /// Creates or restarts `watchSessions/{uid}_{taskId}` with a server-stamped
  /// start time. Restarting means the full duration must pass again.
  Future<void> startSession({required String uid, required String taskId});

  /// The completion write (see firestore.rules `validCompletion`): completion
  /// doc + balance credit + ledger row + session completed, atomically.
  /// Returns the credited reward.
  Future<int> completeTask({
    required String uid,
    required VideoTask task,
    required int reward,
    required int watchedSeconds,
  });
}

class FirestoreWatchRepository implements WatchRepository {
  FirestoreWatchRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> startSession({required String uid, required String taskId}) {
    return _db.collection(FsCol.watchSessions).doc(WatchSession.idFor(uid, taskId)).set({
      FsKeys.uid: uid,
      FsKeys.taskId: taskId,
      FsKeys.status: 'started',
      FsKeys.startedAt: FieldValue.serverTimestamp(),
    }).withWriteTimeout();
  }

  @override
  Future<int> completeTask({
    required String uid,
    required VideoTask task,
    required int reward,
    required int watchedSeconds,
  }) {
    final userRef = _db.collection(FsCol.users).doc(uid);
    final completionRef = userRef.collection(FsCol.completions).doc(task.id);
    final ledgerRef = userRef.collection(FsCol.transactions).doc(TxIds.task(task.id));
    final sessionRef = _db.collection(FsCol.watchSessions).doc(WatchSession.idFor(uid, task.id));

    // A transaction (not a batch) so the absolute balance is computed from a
    // fresh read and the write fails fast when offline instead of queueing.
    return _db.runTransaction<int>((tx) async {
      final userSnap = await tx.get(userRef);
      final completionSnap = await tx.get(completionRef);
      if (completionSnap.exists) throw const AppException(AppStrings.alreadyCompleted);
      final u = userSnap.data();
      if (u == null) throw const AppException(AppStrings.errorNotFound);

      final balance = (u[FsKeys.balance] as num? ?? 0).toInt();
      final totalEarned = (u[FsKeys.totalEarned] as num? ?? 0).toInt();
      final completed = (u[FsKeys.completedTasksCount] as num? ?? 0).toInt();
      final newBalance = balance + reward;

      tx.set(completionRef, {
        FsKeys.taskId: task.id,
        FsKeys.reward: reward,
        FsKeys.completedAt: FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        FsKeys.balance: newBalance,
        FsKeys.totalEarned: totalEarned + reward,
        FsKeys.completedTasksCount: completed + 1,
        FsKeys.lastCompletionTaskId: task.id,
      });
      tx.set(
        ledgerRef,
        WalletTransaction.toCreateMap(
          type: TxType.taskReward,
          amount: reward,
          balanceAfter: newBalance,
          refId: task.id,
          title: _ledgerTitle(task.title),
          createdAt: FieldValue.serverTimestamp(),
        ),
      );
      tx.update(sessionRef, {
        FsKeys.status: 'completed',
        FsKeys.completedAt: FieldValue.serverTimestamp(),
        FsKeys.reportedWatchedSeconds: watchedSeconds,
      });
      return reward;
    }).withWriteTimeout();
  }

  static String _ledgerTitle(String title) {
    final t = title.trim();
    if (t.isEmpty) return AppStrings.txTaskReward;
    return t.length > AppConstants.maxTitleLength ? t.substring(0, AppConstants.maxTitleLength) : t;
  }
}
