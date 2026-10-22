import 'package:flutter_test/flutter_test.dart';
import 'package:video_earn/core/constants/app_strings.dart';
import 'package:video_earn/core/routes/role_guard.dart';
import 'package:video_earn/core/routes/route_names.dart';
import 'package:video_earn/core/utils/date_utils.dart';
import 'package:video_earn/core/utils/formatters.dart';
import 'package:video_earn/core/utils/validators.dart';
import 'package:video_earn/core/utils/youtube_utils.dart';
import 'package:video_earn/data/models/app_settings.dart';
import 'package:video_earn/viewmodels/auth/session_view_model.dart';

void main() {
  group('YoutubeUtils.extractVideoId', () {
    const id = 'dQw4w9WgXcQ';
    for (final url in [
      'https://www.youtube.com/watch?v=$id',
      'https://youtube.com/watch?v=$id&t=10s',
      'https://m.youtube.com/watch?v=$id',
      'https://youtu.be/$id',
      'youtu.be/$id?si=abc',
      'https://www.youtube.com/shorts/$id',
      'https://www.youtube.com/embed/$id',
    ]) {
      test('parses $url', () => expect(YoutubeUtils.extractVideoId(url), id));
    }

    for (final url in [
      '',
      'hello',
      'https://vimeo.com/123',
      'https://youtube.com/watch?v=short',
      'https://youtube.com/channel/x',
    ]) {
      test('rejects "$url"', () => expect(YoutubeUtils.extractVideoId(url), isNull));
    }

    test('thumbnail url', () {
      expect(YoutubeUtils.thumbnailUrl(id), 'https://img.youtube.com/vi/$id/hqdefault.jpg');
    });
  });

  group('Validators', () {
    test('phone', () {
      expect(Validators.phone('03001234567'), isNull);
      expect(Validators.phone('+923001234567'), isNull);
      expect(Validators.phone('0300 1234567'), isNull);
      expect(Validators.phone('3001234567'), AppStrings.invalidPhone);
      expect(Validators.phone('+923001234'), AppStrings.invalidPhone);
    });

    test('email & password', () {
      expect(Validators.email('a.b+c@site.pk'), isNull);
      expect(Validators.email('nope@'), AppStrings.invalidEmail);
      expect(Validators.password('1234567'), AppStrings.passwordTooShort);
      expect(Validators.password('12345678'), isNull);
    });

    test('account number: digits 8-24 or PK IBAN', () {
      expect(Validators.accountNumber('12345678'), isNull);
      expect(Validators.accountNumber('1234567'), AppStrings.invalidAccountNumber);
      expect(Validators.accountNumber('PK36SCBL0000001123456702'), isNull);
      expect(Validators.accountNumber('pk36 scbl 0000 0011 2345 6702'), isNull);
      expect(Validators.accountNumber('GB36SCBL0000001123456702'), AppStrings.invalidAccountNumber);
    });

    test('account holder & transaction id', () {
      expect(Validators.accountHolder('Ali Khan'), isNull);
      expect(Validators.accountHolder('A1'), AppStrings.invalidAccountHolder);
      expect(Validators.transactionId('TXN12345'), isNull);
      expect(Validators.transactionId('TX-1'), AppStrings.invalidTransactionId);
    });

    test('referral code (optional)', () {
      expect(Validators.referralCodeOptional(''), isNull);
      expect(Validators.referralCodeOptional('ab12cd34'), isNull);
      expect(Validators.referralCodeOptional('abc'), AppStrings.invalidReferralFormat);
    });

    test('amountBetween', () {
      final v = Validators.amountBetween(1500, 2000);
      expect(v('1500'), isNull);
      expect(v('1499'), isNotNull);
      expect(v('2001'), isNotNull);
      expect(v('12.5'), AppStrings.invalidAmount);
    });
  });

  group('Formatters', () {
    test('pkr', () {
      expect(Formatters.pkr(1500), 'PKR 1,500');
      expect(Formatters.pkr(0), 'PKR 0');
      expect(Formatters.pkr(-300), '-PKR 300');
      expect(Formatters.pkrSigned(10), '+PKR 10');
    });

    test('duration', () {
      expect(Formatters.duration(65), '1:05');
      expect(Formatters.duration(3725), '1:02:05');
    });

    test('dates are shown in Karachi time (UTC+5)', () {
      final utc = DateTime.utc(2026, 1, 1, 20, 30);
      expect(Formatters.dateTime(utc), '02 Jan 2026, 01:30 AM');
    });
  });

  group('AppDateUtils', () {
    test('start of Karachi day', () {
      // 2026-03-10 22:00 UTC is already 03:00 on 11 March in Karachi.
      final start = AppDateUtils.startOfKarachiDay(DateTime.utc(2026, 3, 10, 22));
      expect(start, DateTime.utc(2026, 3, 10, 19));
    });

    test('withdraw cooldown', () {
      final now = DateTime.utc(2026, 5, 10);
      expect(AppDateUtils.inCooldown(null, 7, now), isFalse);
      expect(AppDateUtils.inCooldown(now.subtract(const Duration(days: 6)), 7, now), isTrue);
      expect(AppDateUtils.inCooldown(now.subtract(const Duration(days: 7)), 7, now), isFalse);
    });
  });

  group('AppSettings', () {
    test('required watch seconds rounds up', () {
      expect(const AppSettings(minWatchPercent: 95).requiredWatchSeconds(61), 58);
    });

    test('version gate', () {
      expect(const AppSettings(minAppVersion: '1.0.0').requiresUpdate, isFalse);
      expect(const AppSettings(minAppVersion: '1.0.1').requiresUpdate, isTrue);
      expect(const AppSettings(minAppVersion: '0.9.9').requiresUpdate, isFalse);
    });
  });

  group('roleGuard', () {
    String? guard(SessionStatus s, String loc, {bool splash = true}) =>
        roleGuard(status: s, splashDone: splash, location: loc);

    test('splash holds until min duration', () {
      expect(guard(SessionStatus.user, Routes.home, splash: false), Routes.splash);
      expect(guard(SessionStatus.user, Routes.splash, splash: false), isNull);
    });

    test('signed out goes to login, auth routes allowed', () {
      expect(guard(SessionStatus.signedOut, Routes.home), Routes.login);
      expect(guard(SessionStatus.signedOut, Routes.signup), isNull);
    });

    test('users cannot open admin routes', () {
      expect(guard(SessionStatus.user, Routes.adminDashboard), Routes.home);
      expect(guard(SessionStatus.user, Routes.adminUser('x')), Routes.home);
      expect(guard(SessionStatus.user, Routes.wallet), isNull);
    });

    test('admins stay in admin area', () {
      expect(guard(SessionStatus.admin, Routes.home), Routes.adminDashboard);
      expect(guard(SessionStatus.admin, Routes.adminSettings), isNull);
    });

    test('maintenance / update / incomplete block everything', () {
      expect(guard(SessionStatus.maintenance, Routes.home), Routes.maintenance);
      expect(guard(SessionStatus.updateRequired, Routes.wallet), Routes.updateRequired);
      expect(guard(SessionStatus.incomplete, Routes.home), Routes.incomplete);
    });
  });
}
