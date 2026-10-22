import '../../core/constants/app_constants.dart';
import 'model_utils.dart';
import 'order_status.dart';

class PromoteOrder {
  const PromoteOrder({
    required this.id,
    required this.uid,
    required this.userName,
    required this.videoUrl,
    required this.youtubeVideoId,
    required this.videoTitle,
    required this.videoDescription,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.durationDays,
    required this.transactionId,
    required this.proofId,
    required this.status,
    this.rejectionReason,
    this.taskId,
    this.createdAt,
    this.reviewedAt,
    this.startAt,
    this.expiresAt,
  });

  final String id;
  final String uid;
  final String userName;
  final String videoUrl;
  final String youtubeVideoId;
  final String videoTitle;
  final String videoDescription;
  final String packageId;
  final String packageName;
  final int price;
  final int durationDays;
  final String transactionId;
  final String proofId;
  final OrderStatus status;
  final String? rejectionReason;
  final String? taskId;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  /// Run period, written by the admin on approval.
  final DateTime? startAt;
  final DateTime? expiresAt;

  factory PromoteOrder.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return PromoteOrder(
      id: doc.id,
      uid: d.str(FsKeys.uid),
      userName: d.str(FsKeys.userName),
      videoUrl: d.str(FsKeys.videoUrl),
      youtubeVideoId: d.str(FsKeys.youtubeVideoId),
      videoTitle: d.str(FsKeys.videoTitle),
      videoDescription: d.str(FsKeys.videoDescription),
      packageId: d.str(FsKeys.packageId),
      packageName: d.str(FsKeys.packageName),
      price: d.integer(FsKeys.price),
      durationDays: d.integer(FsKeys.durationDays, 1),
      transactionId: d.str(FsKeys.transactionId),
      proofId: d.str(FsKeys.proofId),
      status: OrderStatus.parse(d[FsKeys.status]),
      rejectionReason: d.strOrNull(FsKeys.rejectionReason),
      taskId: d.strOrNull(FsKeys.taskId),
      createdAt: d.date(FsKeys.createdAt),
      reviewedAt: d.date(FsKeys.reviewedAt),
      startAt: d.date(FsKeys.startAt),
      expiresAt: d.date(FsKeys.expiresAt),
    );
  }
}
