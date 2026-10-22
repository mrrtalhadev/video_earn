import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../base_view_model.dart';
import 'session_view_model.dart';

/// Login / signup / password-reset actions. Navigation after success is done
/// by the router reacting to [SessionViewModel].
class AuthViewModel extends BaseViewModel {
  AuthViewModel({required AuthRepository auth, required SessionViewModel session}) : _auth = auth, _session = session;

  final AuthRepository _auth;
  final SessionViewModel _session;

  /// Inline error for the referral-code field (signup).
  String? _referralError;
  String? get referralError => _referralError;

  void clearReferralError() {
    if (_referralError == null) return;
    _referralError = null;
    notify();
  }

  Future<bool> login({required String email, required String password}) async {
    _session.clearNotice();
    return runAction(() => _auth.signIn(email: email, password: password));
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _referralError = null;
    _session.clearNotice();
    setState(ViewState.loading);
    _session.beginSignup();
    try {
      await _auth.signUp(
        name: name,
        email: email,
        phone: Validators.normalizePhone(phone),
        password: password,
        referralCode: referralCode,
      );
      setState(ViewState.success);
      return true;
    } catch (e) {
      final error = AppException.from(e);
      if (error.message == AppStrings.referralCodeInvalid) _referralError = error.message;
      setState(ViewState.error, error: error.message);
      return false;
    } finally {
      _session.endSignup();
    }
  }

  Future<bool> sendReset(String email) async {
    return runAction(() => _auth.sendPasswordReset(email));
  }
}
