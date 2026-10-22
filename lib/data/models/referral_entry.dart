import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

/// `referrals/{referrerUid}/referred/{refereeUid}`.
class ReferralEntry {
  const ReferralEntry({
    required this.refereeUid,
    required this.refereeName,
    required this.bonusPaid,
    required this.bonus,
    this.createdAt,
    this.paidAt,
  });

  static const String statusPending = 'pending';
  static const String statusBonusPaid = 'bonus_paid';

  final String refereeUid;
  final String refereeName;
  final bool bonusPaid;
  final int bonus;
  final DateTime? createdAt;
  final DateTime? paidAt;

  factory ReferralEntry.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ReferralEntry(
      refereeUid: doc.id,
      refereeName: d.str(FsKeys.refereeName),
      bonusPaid: d[FsKeys.status] == statusBonusPaid,
      bonus: d.integer(FsKeys.bonus),
      createdAt: d.date(FsKeys.createdAt),
      paidAt: d.date(FsKeys.paidAt),
    );
  }
}
