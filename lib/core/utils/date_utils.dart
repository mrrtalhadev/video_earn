import '../constants/app_constants.dart';

/// Asia/Karachi (UTC+5, no DST) date helpers.
abstract final class AppDateUtils {
  /// Shifts [time] to a UTC DateTime whose wall-clock fields equal Karachi time.
  static DateTime toKarachi(DateTime time) => time.toUtc().add(AppConstants.karachiOffset);

  /// Start of the current Karachi day, as a real UTC instant.
  static DateTime startOfKarachiDay([DateTime? now]) {
    final k = toKarachi(now ?? DateTime.now());
    return DateTime.utc(k.year, k.month, k.day).subtract(AppConstants.karachiOffset);
  }

  static DateTime? nextWithdrawAt(DateTime? lastWithdrawAt, int cooldownDays) =>
      lastWithdrawAt?.add(Duration(days: cooldownDays));

  static bool inCooldown(DateTime? lastWithdrawAt, int cooldownDays, [DateTime? now]) {
    final next = nextWithdrawAt(lastWithdrawAt, cooldownDays);
    return next != null && (now ?? DateTime.now()).isBefore(next);
  }
}
