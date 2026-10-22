import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/withdraw_repository.dart';
import '../auth/session_view_model.dart';
import '../base_view_model.dart';

class WithdrawViewModel extends BaseViewModel {
  WithdrawViewModel({required WithdrawRepository repo, required SessionViewModel session})
    : _repo = repo,
      _session = session;

  final WithdrawRepository _repo;
  final SessionViewModel _session;

  AppUser? get user => _session.user;
  AppSettings get settings => _session.settingsOrDefault;

  DateTime? get nextAvailableAt => AppDateUtils.nextWithdrawAt(user?.lastWithdrawAt, settings.withdrawCooldownDays);

  /// Why the form is disabled, or null when the user may withdraw.
  String? get blockedReason {
    final u = user;
    if (u == null || !_session.hasSettings) return AppStrings.settingsNotLoaded;
    if (!u.canEarn) return AppStrings.withdrawNotSubscribed;
    if (u.balance < settings.minWithdraw) {
      return AppStrings.withdrawBalanceTooLow(Formatters.pkr(settings.minWithdraw));
    }
    if (AppDateUtils.inCooldown(u.lastWithdrawAt, settings.withdrawCooldownDays)) {
      return AppStrings.withdrawCooldownActive(Formatters.dateTime(nextAvailableAt));
    }
    return null;
  }

  Future<bool> submit({
    required int amount,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
  }) {
    return runAction(
      () => _repo.submit(
        uid: _session.uid!,
        amount: amount,
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountNumber: Validators.normalizeAccount(accountNumber),
      ),
    );
  }
}
