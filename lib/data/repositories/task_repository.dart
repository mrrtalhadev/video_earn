import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/video_task.dart';
import 'page_result.dart';

enum AdminTaskFilter { all, admin, promote, expired }

abstract class TaskRepository {
  /// Active, unexpired tasks (max 100), sorted by `order` then newest.
  Future<List<VideoTask>> fetchVisibleTasks();

  /// Ids of tasks this user has already completed.
  Future<Set<String>> fetchCompletedTaskIds(String uid);

  // Admin
  Future<PageResult<VideoTask>> fetchAdminPage(AdminTaskFilter filter, {JsonDoc? startAfter});
  Future<void> createTask(Map<String, dynamic> data);
  Future<void> updateTask(String id, Map<String, dynamic> data);
  Future<void> deleteTask(String id);
  Future<int> countExpired();
  Future<int> purgeExpired();
}

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tasks => _db.collection(FsCol.tasks);

  @override
  Future<List<VideoTask>> fetchVisibleTasks() async {
    final now = DateTime.now();
    final snap = await _tasks
        .where(FsKeys.isActive, isEqualTo: true)
        .where(FsKeys.expiresAt, isGreaterThan: Timestamp.fromDate(now))
        .orderBy(FsKeys.expiresAt)
        .limit(AppConstants.visibleTasksLimit)
        .get();
    final tasks =
        snap.docs
            .map(VideoTask.fromDoc)
            .where((t) => t.startAt == null || !t.startAt!.isAfter(now))
            .where((t) => t.youtubeVideoId.isNotEmpty && t.durationSeconds > 0)
            .toList()
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            if (byOrder != 0) return byOrder;
            final ac = a.createdAt ?? DateTime(2000), bc = b.createdAt ?? DateTime(2000);
            return bc.compareTo(ac);
          });
    return tasks;
  }

  @override
  Future<Set<String>> fetchCompletedTaskIds(String uid) async {
    final snap = await _db.collection(FsCol.users).doc(uid).collection(FsCol.completions).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  @override
  Future<PageResult<VideoTask>> fetchAdminPage(AdminTaskFilter filter, {JsonDoc? startAfter}) {
    final now = Timestamp.now();
    final JsonQuery q = switch (filter) {
      AdminTaskFilter.all => _tasks.orderBy(FsKeys.createdAt, descending: true),
      AdminTaskFilter.admin =>
        _tasks.where(FsKeys.source, isEqualTo: TaskSource.admin.name).orderBy(FsKeys.createdAt, descending: true),
      AdminTaskFilter.promote =>
        _tasks.where(FsKeys.source, isEqualTo: TaskSource.promote.name).orderBy(FsKeys.createdAt, descending: true),
      AdminTaskFilter.expired =>
        _tasks.where(FsKeys.expiresAt, isLessThanOrEqualTo: now).orderBy(FsKeys.expiresAt, descending: true),
    };
    return fetchPage(q, VideoTask.fromDoc, startAfter: startAfter);
  }

  @override
  Future<void> createTask(Map<String, dynamic> data) => _tasks.add({
    ...data,
    FsKeys.startAt: FieldValue.serverTimestamp(),
    FsKeys.createdAt: FieldValue.serverTimestamp(),
  }).withWriteTimeout();

  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) => _tasks.doc(id).update(data).withWriteTimeout();

  @override
  Future<void> deleteTask(String id) => _tasks.doc(id).delete().withWriteTimeout();

  JsonQuery get _expiredQuery => _tasks.where(FsKeys.expiresAt, isLessThanOrEqualTo: Timestamp.now());

  @override
  Future<int> countExpired() async => (await _expiredQuery.count().get()).count ?? 0;

  @override
  Future<int> purgeExpired() async {
    var deleted = 0;
    while (true) {
      final snap = await _expiredQuery.limit(400).get();
      if (snap.docs.isEmpty) return deleted;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit().withWriteTimeout();
      deleted += snap.docs.length;
      if (snap.docs.length < 400) return deleted;
    }
  }
}
