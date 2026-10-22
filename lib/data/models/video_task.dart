import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/youtube_utils.dart';
import 'model_utils.dart';

enum TaskSource {
  admin,
  promote;

  static TaskSource parse(Object? v) => v == 'promote' ? TaskSource.promote : TaskSource.admin;
}

class VideoTask {
  const VideoTask({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.source,
    this.ownerUid,
    this.promoteOrderId,
    required this.isActive,
    this.startAt,
    required this.expiresAt,
    this.order = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String youtubeUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final TaskSource source;
  final String? ownerUid;
  final String? promoteOrderId;
  final bool isActive;
  final DateTime? startAt;
  final DateTime expiresAt;
  final int order;
  final DateTime? createdAt;

  bool isExpired([DateTime? now]) => !expiresAt.isAfter(now ?? DateTime.now());
  bool isVisible([DateTime? now]) => isActive && !isExpired(now);

  factory VideoTask.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final videoId = d.str(FsKeys.youtubeVideoId);
    return VideoTask(
      id: doc.id,
      title: d.str(FsKeys.title),
      description: d.str(FsKeys.description),
      youtubeVideoId: videoId,
      youtubeUrl: d.str(FsKeys.youtubeUrl),
      thumbnailUrl: d.str(FsKeys.thumbnailUrl, YoutubeUtils.thumbnailUrl(videoId)),
      durationSeconds: d.integer(FsKeys.durationSeconds),
      source: TaskSource.parse(d[FsKeys.source]),
      ownerUid: d.strOrNull(FsKeys.ownerUid),
      promoteOrderId: d.strOrNull(FsKeys.promoteOrderId),
      isActive: d.boolean(FsKeys.isActive),
      startAt: d.date(FsKeys.startAt),
      expiresAt: d.date(FsKeys.expiresAt) ?? AppConstants.adminTaskExpiry,
      order: d.integer(FsKeys.order),
      createdAt: d.date(FsKeys.createdAt),
    );
  }

  /// Fields for an admin-created task (create or full edit).
  static Map<String, dynamic> adminMap({
    required String title,
    required String description,
    required String videoId,
    required int durationSeconds,
    required bool isActive,
    required int order,
  }) => {
    FsKeys.title: title,
    FsKeys.description: description,
    FsKeys.youtubeVideoId: videoId,
    FsKeys.youtubeUrl: YoutubeUtils.watchUrl(videoId),
    FsKeys.thumbnailUrl: YoutubeUtils.thumbnailUrl(videoId),
    FsKeys.durationSeconds: durationSeconds,
    FsKeys.source: TaskSource.admin.name,
    FsKeys.ownerUid: null,
    FsKeys.promoteOrderId: null,
    FsKeys.isActive: isActive,
    FsKeys.expiresAt: Timestamp.fromDate(AppConstants.adminTaskExpiry),
    FsKeys.order: order,
  };
}
