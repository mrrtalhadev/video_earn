import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// External links (WhatsApp, email, phone). Each returns false if nothing
/// could handle the link, so the UI can show a friendly message.
abstract final class LinkUtils {
  static Future<bool> whatsapp(String number) {
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');
    // Local 03XXXXXXXXX → international 923XXXXXXXXX.
    final intl = digits.startsWith('0') ? '92${digits.substring(1)}' : digits;
    return _open(Uri.parse('${AppConstants.whatsappBase}$intl'));
  }

  static Future<bool> email(String address) => _open(Uri(scheme: 'mailto', path: address.trim()));

  static Future<bool> phone(String number) => _open(Uri(scheme: 'tel', path: number.trim()));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
