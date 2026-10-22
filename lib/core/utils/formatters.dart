import 'package:intl/intl.dart';

import '../constants/app_strings.dart';
import 'date_utils.dart';

abstract final class Formatters {
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a', 'en_US');
  static final DateFormat _date = DateFormat('dd MMM yyyy', 'en_US');
  static final DateFormat _time = DateFormat('hh:mm a', 'en_US');

  /// `1500` → `PKR 1,500`.
  static String pkr(int amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${AppStrings.currency} ${_int.format(amount.abs())}';
  }

  /// Signed amount for ledgers: `+PKR 10` / `-PKR 1,500`.
  static String pkrSigned(int amount) => amount > 0 ? '+${pkr(amount)}' : pkr(amount);

  static String number(int value) => _int.format(value);

  /// Dates are always displayed in Asia/Karachi time.
  static String dateTime(DateTime? value) => value == null ? '—' : _dateTime.format(AppDateUtils.toKarachi(value));

  static String date(DateTime? value) => value == null ? '—' : _date.format(AppDateUtils.toKarachi(value));

  static String time(DateTime? value) => value == null ? '—' : _time.format(AppDateUtils.toKarachi(value));

  /// Seconds → `m:ss` or `h:mm:ss`.
  static String duration(int totalSeconds) {
    final d = Duration(seconds: totalSeconds < 0 ? 0 : totalSeconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}
