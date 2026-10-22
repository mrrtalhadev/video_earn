/// Non-user-facing constants: app config, Firestore collection names and
/// Firestore field keys. User-facing text lives in `app_strings.dart`.
abstract final class AppConstants {
  /// Must match `version` in pubspec.yaml (name part). Compared against
  /// `settings/app.minAppVersion` to force updates.
  static const String appVersion = '1.0.0';

  /// Pakistan Standard Time is UTC+5 with no DST.
  static const Duration karachiOffset = Duration(hours: 5);

  /// Admin-created tasks never expire; they use this far-future expiry so
  /// every task can be queried with `expiresAt > now`.
  static final DateTime adminTaskExpiry = DateTime.utc(2099, 12, 31);

  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration writeTimeout = Duration(seconds: 30);

  static const int visibleTasksLimit = 100;
  static const int homeTasksPreview = 5;
  static const int pageSize = 20;
  static const int recentTransactions = 10;

  static const int referralCodeLength = 8;
  static const int referralCodeRetries = 5;
  static const String referralCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Payment screenshot compression targets (Firestore docs are capped at
  /// 1 MiB; rules hard-cap the blob at 600 KB).
  static const int proofTargetBytes = 400 * 1000;
  static const int proofMaxWidth = 1080;
  static const int proofStartQuality = 60;

  /// Seek detection tolerance for the video player.
  static const int seekToleranceSeconds = 3;

  /// Max multiple of the video duration a session may stay open before a
  /// completion is rejected by the rules.
  static const int maxSessionDurationFactor = 3;

  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxReasonLength = 300;
  static const int maxContentLength = 20000;

  static const String youtubeThumbnail = 'https://img.youtube.com/vi/{id}/hqdefault.jpg';
  static const String youtubeWatch = 'https://www.youtube.com/watch?v={id}';
  static const String whatsappBase = 'https://wa.me/';
  static const String proofMimeType = 'image/jpeg';
}

/// Firestore collection / document ids.
abstract final class FsCol {
  static const String admins = 'admins';
  static const String users = 'users';
  static const String referralCodes = 'referralCodes';
  static const String referrals = 'referrals';
  static const String referred = 'referred';
  static const String tasks = 'tasks';
  static const String watchSessions = 'watchSessions';
  static const String completions = 'completions';
  static const String transactions = 'transactions';
  static const String paymentProofs = 'paymentProofs';
  static const String subscriptionOrders = 'subscriptionOrders';
  static const String withdrawRequests = 'withdrawRequests';
  static const String promotePackages = 'promotePackages';
  static const String promoteOrders = 'promoteOrders';
  static const String settings = 'settings';
  static const String settingsDoc = 'app';
  static const String faqs = 'faqs';
}

/// Firestore field keys.
abstract final class FsKeys {
  // Common
  static const String uid = 'uid';
  static const String createdAt = 'createdAt';
  static const String status = 'status';
  static const String amount = 'amount';
  static const String title = 'title';
  static const String description = 'description';
  static const String isActive = 'isActive';
  static const String sortOrder = 'sortOrder';
  static const String reviewedAt = 'reviewedAt';
  static const String reviewedBy = 'reviewedBy';
  static const String rejectionReason = 'rejectionReason';
  static const String userName = 'userName';
  static const String userEmail = 'userEmail';
  static const String transactionId = 'transactionId';
  static const String proofId = 'proofId';

  // Users
  static const String name = 'name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String nameLower = 'nameLower';
  static const String photoUrl = 'photoUrl';
  static const String isBlocked = 'isBlocked';
  static const String subscriptionActive = 'subscriptionActive';
  static const String subscriptionActivatedAt = 'subscriptionActivatedAt';
  static const String hasPendingSubscription = 'hasPendingSubscription';
  static const String balance = 'balance';
  static const String totalEarned = 'totalEarned';
  static const String totalReferralEarned = 'totalReferralEarned';
  static const String totalWithdrawn = 'totalWithdrawn';
  static const String pendingWithdraw = 'pendingWithdraw';
  static const String completedTasksCount = 'completedTasksCount';
  static const String referralCode = 'referralCode';
  static const String referredBy = 'referredBy';
  static const String referredByCode = 'referredByCode';
  static const String referralBonusPaid = 'referralBonusPaid';
  static const String referralCount = 'referralCount';
  static const String lastWithdrawAt = 'lastWithdrawAt';
  static const String lastWithdrawRequestId = 'lastWithdrawRequestId';
  static const String lastCompletionTaskId = 'lastCompletionTaskId';

  // Referrals
  static const String refereeName = 'refereeName';
  static const String bonus = 'bonus';
  static const String paidAt = 'paidAt';

  // Tasks
  static const String youtubeVideoId = 'youtubeVideoId';
  static const String youtubeUrl = 'youtubeUrl';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String durationSeconds = 'durationSeconds';
  static const String source = 'source';
  static const String ownerUid = 'ownerUid';
  static const String promoteOrderId = 'promoteOrderId';
  static const String startAt = 'startAt';
  static const String expiresAt = 'expiresAt';
  static const String order = 'order';

  // Watch sessions / completions
  static const String taskId = 'taskId';
  static const String startedAt = 'startedAt';
  static const String completedAt = 'completedAt';
  static const String reportedWatchedSeconds = 'reportedWatchedSeconds';
  static const String reward = 'reward';

  // Transactions
  static const String type = 'type';
  static const String balanceAfter = 'balanceAfter';
  static const String refId = 'refId';

  // Proofs
  static const String bytes = 'bytes';
  static const String mimeType = 'mimeType';
  static const String sizeBytes = 'sizeBytes';

  // Orders
  static const String priceAtSubmission = 'priceAtSubmission';
  static const String accountHolderName = 'accountHolderName';
  static const String bankName = 'bankName';
  static const String accountNumber = 'accountNumber';
  static const String adminTransferRef = 'adminTransferRef';
  static const String prevLastWithdrawAt = 'prevLastWithdrawAt';
  static const String videoUrl = 'videoUrl';
  static const String videoTitle = 'videoTitle';
  static const String videoDescription = 'videoDescription';
  static const String packageId = 'packageId';
  static const String packageName = 'packageName';
  static const String price = 'price';
  static const String durationDays = 'durationDays';

  // Settings
  static const String subscriptionPrice = 'subscriptionPrice';
  static const String videoReward = 'videoReward';
  static const String referralBonus = 'referralBonus';
  static const String minWithdraw = 'minWithdraw';
  static const String withdrawCooldownDays = 'withdrawCooldownDays';
  static const String minWatchPercent = 'minWatchPercent';
  static const String maxVideoMinutes = 'maxVideoMinutes';
  static const String bank = 'bank';
  static const String accountTitle = 'accountTitle';
  static const String iban = 'iban';
  static const String supportWhatsapp = 'supportWhatsapp';
  static const String supportEmail = 'supportEmail';
  static const String aboutUs = 'aboutUs';
  static const String termsAndConditions = 'termsAndConditions';
  static const String contactUs = 'contactUs';
  static const String address = 'address';
  static const String whatsapp = 'whatsapp';
  static const String maintenanceMode = 'maintenanceMode';
  static const String minAppVersion = 'minAppVersion';

  // FAQ
  static const String question = 'question';
  static const String answer = 'answer';
}
