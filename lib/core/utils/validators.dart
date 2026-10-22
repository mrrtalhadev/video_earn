import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import 'formatters.dart';
import 'youtube_utils.dart';

/// Form validators. Each returns an error message from [AppStrings] or null.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _phone = RegExp(r'^(03\d{9}|\+923\d{9})$');
  static final RegExp _holder = RegExp(r'^[A-Za-z][A-Za-z ]{2,}$');
  static final RegExp _digits = RegExp(r'^\d{8,24}$');
  static final RegExp _iban = RegExp(r'^PK[A-Z0-9]{22}$');
  static final RegExp _txn = RegExp(r'^[A-Za-z0-9]{6,40}$');
  static final RegExp _referral = RegExp(r'^[A-Z0-9]{8}$');
  static final RegExp _version = RegExp(r'^\d+\.\d+\.\d+$');

  static String? required(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null;

  static String? name(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    if (v!.trim().length < 3) return AppStrings.nameTooShort;
    if (v.trim().length > AppConstants.maxTitleLength) {
      return AppStrings.tooLong(AppConstants.maxTitleLength);
    }
    return null;
  }

  static String? email(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return _email.hasMatch(v!.trim()) ? null : AppStrings.invalidEmail;
  }

  static String? phone(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return _phone.hasMatch(v!.trim().replaceAll(' ', '')) ? null : AppStrings.invalidPhone;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
    return v.length < 8 ? AppStrings.passwordTooShort : null;
  }

  static String? Function(String?) confirmPassword(String Function() original) => (v) {
    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
    return v == original() ? null : AppStrings.passwordsDontMatch;
  };

  static String? referralCodeOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return _referral.hasMatch(v.trim().toUpperCase()) ? null : AppStrings.invalidReferralFormat;
  }

  static String? accountHolder(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return _holder.hasMatch(v!.trim()) ? null : AppStrings.invalidAccountHolder;
  }

  static String? accountNumber(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    final s = v!.replaceAll(' ', '').toUpperCase();
    return (_digits.hasMatch(s) || _iban.hasMatch(s)) ? null : AppStrings.invalidAccountNumber;
  }

  static String? transactionId(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return _txn.hasMatch(v!.trim()) ? null : AppStrings.invalidTransactionId;
  }

  static String? youtubeUrl(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return YoutubeUtils.extractVideoId(v!) == null ? AppStrings.invalidYoutubeUrl : null;
  }

  static String? title(String? v) => maxLength(v, AppConstants.maxTitleLength, isRequired: true);

  static String? description(String? v) => maxLength(v, AppConstants.maxDescriptionLength, isRequired: false);

  static String? maxLength(String? v, int max, {required bool isRequired}) {
    if (isRequired && required(v) != null) return AppStrings.fieldRequired;
    return (v ?? '').trim().length > max ? AppStrings.tooLong(max) : null;
  }

  static String? positiveInt(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    final n = int.tryParse(v!.trim());
    return (n == null || n <= 0) ? AppStrings.invalidPositiveNumber : null;
  }

  static String? nonNegativeInt(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    final n = int.tryParse(v!.trim());
    return (n == null || n < 0) ? AppStrings.invalidNumber : null;
  }

  static String? percent(String? v) {
    final base = positiveInt(v);
    if (base != null) return base;
    return int.parse(v!.trim()) > 100 ? AppStrings.percentRange : null;
  }

  static String? version(String? v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    return _version.hasMatch(v!.trim()) ? null : AppStrings.invalidVersion;
  }

  static String? Function(String?) amountBetween(int min, int max) => (v) {
    if (required(v) != null) return AppStrings.fieldRequired;
    final n = int.tryParse(v!.trim());
    if (n == null || n <= 0) return AppStrings.invalidAmount;
    if (n < min) return AppStrings.minAmount(Formatters.pkr(min));
    if (n > max) return AppStrings.maxAmount(Formatters.pkr(max));
    return null;
  };

  static String normalizePhone(String v) => v.trim().replaceAll(' ', '');
  static String normalizeAccount(String v) => v.replaceAll(' ', '').toUpperCase();
}
