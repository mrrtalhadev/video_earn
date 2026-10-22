import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

/// `watchSessions/{uid}_{taskId}` — one per user per task.
class WatchSession {
  const WatchSession({
    required this.id,
    required this.uid,
    required this.taskId,
    this.startedAt,
    required this.completed,
    this.completedAt,
    this.reportedWatchedSeconds,
  });

  final String id;
  final String uid;
  final String taskId;
  final DateTime? startedAt;
  final bool completed;
  final DateTime? completedAt;
  final int? reportedWatchedSeconds;

  static String idFor(String uid, String taskId) => '${uid}_$taskId';

  factory WatchSession.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return WatchSession(
      id: doc.id,
      uid: d.str(FsKeys.uid),
      taskId: d.str(FsKeys.taskId),
      startedAt: d.date(FsKeys.startedAt),
      completed: d[FsKeys.status] == 'completed',
      completedAt: d.date(FsKeys.completedAt),
      reportedWatchedSeconds: d[FsKeys.reportedWatchedSeconds] is int ? d[FsKeys.reportedWatchedSeconds] as int : null,
    );
  }
}
