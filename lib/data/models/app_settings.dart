import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

class BankDetails {
  const BankDetails({this.bankName = '', this.accountTitle = '', this.accountNumber = '', this.iban = ''});

  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final String iban;

  bool get isConfigured => accountNumber.isNotEmpty || iban.isNotEmpty;

  factory BankDetails.fromMap(Map<String, dynamic> m) => BankDetails(
    bankName: m.str(FsKeys.bankName),
    accountTitle: m.str(FsKeys.accountTitle),
    accountNumber: m.str(FsKeys.accountNumber),
    iban: m.str(FsKeys.iban),
  );

  Map<String, dynamic> toMap() => {
    FsKeys.bankName: bankName,
    FsKeys.accountTitle: accountTitle,
    FsKeys.accountNumber: accountNumber,
    FsKeys.iban: iban,
  };
}

class ContactInfo {
  const ContactInfo({this.phone = '', this.email = '', this.address = '', this.whatsapp = ''});

  final String phone;
  final String email;
  final String address;
  final String whatsapp;

  bool get isEmpty => phone.isEmpty && email.isEmpty && address.isEmpty && whatsapp.isEmpty;

  factory ContactInfo.fromMap(Map<String, dynamic> m) => ContactInfo(
    phone: m.str(FsKeys.phone),
    email: m.str(FsKeys.email),
    address: m.str(FsKeys.address),
    whatsapp: m.str(FsKeys.whatsapp),
  );

  Map<String, dynamic> toMap() => {
    FsKeys.phone: phone,
    FsKeys.email: email,
    FsKeys.address: address,
    FsKeys.whatsapp: whatsapp,
  };
}

/// `settings/app` — the single admin-editable config document.
class AppSettings {
  const AppSettings({
    this.subscriptionPrice = 1500,
    this.videoReward = 10,
    this.referralBonus = 300,
    this.minWithdraw = 1500,
    this.withdrawCooldownDays = 7,
    this.minWatchPercent = 95,
    this.maxVideoMinutes = 20,
    this.bank = const BankDetails(),
    this.supportWhatsapp = '',
    this.supportEmail = '',
    this.aboutUs = '',
    this.termsAndConditions = '',
    this.contactUs = const ContactInfo(),
    this.maintenanceMode = false,
    this.minAppVersion = AppConstants.appVersion,
  });

  final int subscriptionPrice;
  final int videoReward;
  final int referralBonus;
  final int minWithdraw;
  final int withdrawCooldownDays;
  final int minWatchPercent;
  final int maxVideoMinutes;
  final BankDetails bank;
  final String supportWhatsapp;
  final String supportEmail;
  final String aboutUs;
  final String termsAndConditions;
  final ContactInfo contactUs;
  final bool maintenanceMode;
  final String minAppVersion;

  factory AppSettings.fromMap(Map<String, dynamic> d) => AppSettings(
    subscriptionPrice: d.integer(FsKeys.subscriptionPrice, 1500),
    videoReward: d.integer(FsKeys.videoReward, 10),
    referralBonus: d.integer(FsKeys.referralBonus, 300),
    minWithdraw: d.integer(FsKeys.minWithdraw, 1500),
    withdrawCooldownDays: d.integer(FsKeys.withdrawCooldownDays, 7),
    minWatchPercent: d.integer(FsKeys.minWatchPercent, 95),
    maxVideoMinutes: d.integer(FsKeys.maxVideoMinutes, 20),
    bank: BankDetails.fromMap(d.subMap(FsKeys.bank)),
    supportWhatsapp: d.str(FsKeys.supportWhatsapp),
    supportEmail: d.str(FsKeys.supportEmail),
    aboutUs: d.str(FsKeys.aboutUs),
    termsAndConditions: d.str(FsKeys.termsAndConditions),
    contactUs: ContactInfo.fromMap(d.subMap(FsKeys.contactUs)),
    maintenanceMode: d.boolean(FsKeys.maintenanceMode),
    minAppVersion: d.str(FsKeys.minAppVersion, AppConstants.appVersion),
  );

  Map<String, dynamic> toMap() => {
    FsKeys.subscriptionPrice: subscriptionPrice,
    FsKeys.videoReward: videoReward,
    FsKeys.referralBonus: referralBonus,
    FsKeys.minWithdraw: minWithdraw,
    FsKeys.withdrawCooldownDays: withdrawCooldownDays,
    FsKeys.minWatchPercent: minWatchPercent,
    FsKeys.maxVideoMinutes: maxVideoMinutes,
    FsKeys.bank: bank.toMap(),
    FsKeys.supportWhatsapp: supportWhatsapp,
    FsKeys.supportEmail: supportEmail,
    FsKeys.aboutUs: aboutUs,
    FsKeys.termsAndConditions: termsAndConditions,
    FsKeys.contactUs: contactUs.toMap(),
    FsKeys.maintenanceMode: maintenanceMode,
    FsKeys.minAppVersion: minAppVersion,
  };

  /// Seconds of real time a video of [durationSeconds] must play before the
  /// rules accept a completion.
  int requiredWatchSeconds(int durationSeconds) => (durationSeconds * minWatchPercent / 100).ceil();

  /// True if [AppConstants.appVersion] is older than [minAppVersion].
  bool get requiresUpdate => _compare(AppConstants.appVersion, minAppVersion) < 0;

  static int _compare(String a, String b) {
    List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList()..addAll([0, 0, 0]);
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return 0;
  }

  AppSettings copyWith({
    int? subscriptionPrice,
    int? videoReward,
    int? referralBonus,
    int? minWithdraw,
    int? withdrawCooldownDays,
    int? minWatchPercent,
    int? maxVideoMinutes,
    BankDetails? bank,
    String? supportWhatsapp,
    String? supportEmail,
    String? aboutUs,
    String? termsAndConditions,
    ContactInfo? contactUs,
    bool? maintenanceMode,
    String? minAppVersion,
  }) => AppSettings(
    subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
    videoReward: videoReward ?? this.videoReward,
    referralBonus: referralBonus ?? this.referralBonus,
    minWithdraw: minWithdraw ?? this.minWithdraw,
    withdrawCooldownDays: withdrawCooldownDays ?? this.withdrawCooldownDays,
    minWatchPercent: minWatchPercent ?? this.minWatchPercent,
    maxVideoMinutes: maxVideoMinutes ?? this.maxVideoMinutes,
    bank: bank ?? this.bank,
    supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
    supportEmail: supportEmail ?? this.supportEmail,
    aboutUs: aboutUs ?? this.aboutUs,
    termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    contactUs: contactUs ?? this.contactUs,
    maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    minAppVersion: minAppVersion ?? this.minAppVersion,
  );
}
