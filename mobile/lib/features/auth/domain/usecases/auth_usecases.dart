import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../entities/auth_config.dart';
import '../entities/external_credential.dart';
import '../entities/me.dart';
import '../repositories/auth_repository.dart';
import '../repositories/external_identity_repository.dart';

@injectable
class WatchSession {
  const WatchSession(this._auth);

  final AuthRepository _auth;

  Stream<Me?> call() => _auth.sessionChanges;
}

@injectable
class GetAuthConfig {
  const GetAuthConfig(this._auth);

  final AuthRepository _auth;

  Future<AuthConfig> call() => _auth.getConfig();
}

@injectable
class RestoreSession {
  const RestoreSession(this._auth);

  final AuthRepository _auth;

  Future<Result<Me?>> call() => _auth.restoreSession();
}

@injectable
class SignIn {
  const SignIn(this._auth);

  final AuthRepository _auth;

  Future<Result<Me>> call({required String phoneNumber, required String password}) =>
      _auth.signIn(phoneNumber: phoneNumber, password: password);
}

@injectable
class Register {
  const Register(this._auth);

  final AuthRepository _auth;

  Future<Result<Me>> call({
    required String phoneNumber,
    required String password,
    required String recoveryPin,
    required String uiLanguage,
  }) =>
      _auth.register(phoneNumber: phoneNumber, password: password, recoveryPin: recoveryPin, uiLanguage: uiLanguage);
}

@injectable
class VerifyRecoveryPin {
  const VerifyRecoveryPin(this._auth);

  final AuthRepository _auth;

  Future<Result<String>> call({required String phoneNumber, required String pin}) =>
      _auth.verifyRecoveryPin(phoneNumber: phoneNumber, pin: pin);
}

@injectable
class ResetPassword {
  const ResetPassword(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call({required String resetToken, required String newPassword}) =>
      _auth.resetPassword(resetToken: resetToken, newPassword: newPassword);
}

@injectable
class SignOut {
  const SignOut(this._auth, this._identities);

  final AuthRepository _auth;
  final ExternalIdentityRepository _identities;

  Future<void> call() async {
    await _auth.signOut();
    await _identities.forget(); // the next "Continue with Google" shows the account picker again
  }
}

@injectable
class SignOutEverywhere {
  const SignOutEverywhere(this._auth);

  final AuthRepository _auth;

  Future<Result<Me>> call() => _auth.signOutEverywhere();
}

@injectable
class GetMe {
  const GetMe(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call() => _accounts.getMe();
}

@injectable
class CheckUsername {
  const CheckUsername(this._accounts);

  final AccountRepository _accounts;

  Future<Result<UsernameAvailability>> call(String username) => _accounts.checkUsername(username);
}

@injectable
class CompleteProfile {
  const CompleteProfile(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call({required String displayName, required String username, String? avatarUrl}) =>
      _accounts.completeProfile(displayName: displayName.trim(), username: username.trim(), avatarUrl: avatarUrl);
}

@injectable
class SetRecoveryPin {
  const SetRecoveryPin(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call(String pin) => _accounts.setRecoveryPin(pin);
}

@injectable
class ChangeRecoveryPin {
  const ChangeRecoveryPin(this._accounts);

  final AccountRepository _accounts;

  Future<Result<void>> call({required String currentPassword, required String newPin}) =>
      _accounts.changeRecoveryPin(currentPassword: currentPassword, newPin: newPin);
}

@injectable
class ChangePassword {
  const ChangePassword(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call({required String currentPassword, required String newPassword}) =>
      _accounts.changePassword(currentPassword: currentPassword, newPassword: newPassword);
}

@injectable
class ChangePhoneNumber {
  const ChangePhoneNumber(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call({required String newPhoneNumber, required String currentPassword}) =>
      _accounts.changePhoneNumber(newPhoneNumber: newPhoneNumber, currentPassword: currentPassword);
}

/// Deletes the account for good, right away (SPEC F01). On success this device has forgotten the account and its
/// session; on a failure nothing changed and nothing is retried by itself.
@injectable
class DeleteAccount {
  const DeleteAccount(this._accounts);

  final AccountRepository _accounts;

  Future<Result<void>> call({String? password, ExternalCredential? external}) =>
      _accounts.deleteAccount(password: password, external: external);
}

// ── Google / Apple (ADR 0012) ───────────────────────────────────────

/// The Google / Apple buttons to show: configured on the server and possible on this device.
@injectable
class GetExternalProviders {
  const GetExternalProviders(this._auth, this._identities);

  final AuthRepository _auth;
  final ExternalIdentityRepository _identities;

  Future<List<ExternalProvider>> call() async =>
      [for (final provider in (await _auth.getConfig()).externalProviders) if (_identities.supports(provider)) provider];
}

/// The provider's sheet; `Ok(null)` when the person closes it.
@injectable
class ObtainExternalCredential {
  const ObtainExternalCredential(this._identities);

  final ExternalIdentityRepository _identities;

  Future<Result<ExternalCredential?>> call(ExternalProvider provider) => _identities.obtain(provider);
}

/// "Confirm it's you" for an account without a password: a fresh token of a provider linked to [me] that this device
/// can show. `Ok(null)` when the person closes the sheet.
@injectable
class ConfirmWithLinkedProvider {
  const ConfirmWithLinkedProvider(this._identities);

  final ExternalIdentityRepository _identities;

  /// The provider that [call] will ask, or null when none can be shown here.
  ExternalProvider? providerFor(Me me) => providersFor(me).firstOrNull;

  /// Every provider linked to [me] that this device can show, in the order they were linked.
  List<ExternalProvider> providersFor(Me me) =>
      me.externalLogins.map((login) => login.kind).nonNulls.where(_identities.supports).toList();

  /// Whether this device can show [provider]'s sheet (Apple: iOS only for now).
  bool supports(ExternalProvider provider) => _identities.supports(provider);

  Future<Result<ExternalCredential?>> call(Me me) async {
    final provider = providerFor(me);
    if (provider == null) return const Err(Failure(FailureCodes.authConfirmationRequired));
    return _identities.obtain(provider);
  }

  /// The sheet of one [provider]: a button the person chose, or Apple when the server asks for it.
  Future<Result<ExternalCredential?>> using(ExternalProvider provider) async {
    if (!_identities.supports(provider)) return const Err(Failure(FailureCodes.authConfirmationRequired));
    return _identities.obtain(provider);
  }
}

@injectable
class SignInWithExternal {
  const SignInWithExternal(this._auth);

  final AuthRepository _auth;

  Future<Result<Me>> call(
    ExternalCredential credential, {
    required String uiLanguage,
    bool createAccount = false,
    ExternalLink? link,
  }) =>
      _auth.signInWithExternal(credential, uiLanguage: uiLanguage, createAccount: createAccount, link: link);
}

@injectable
class LinkExternalLogin {
  const LinkExternalLogin(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call(ExternalCredential credential, {String? password, ExternalCredential? external}) =>
      _accounts.linkExternalLogin(credential, password: password, external: external);
}

@injectable
class UnlinkExternalLogin {
  const UnlinkExternalLogin(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call(ExternalProvider provider) => _accounts.unlinkExternalLogin(provider);
}

@injectable
class AddPhoneSignIn {
  const AddPhoneSignIn(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call({
    required String phoneNumber,
    required String password,
    required String recoveryPin,
    required ExternalCredential external,
  }) =>
      _accounts.addPhoneSignIn(phoneNumber: phoneNumber, password: password, recoveryPin: recoveryPin, external: external);
}
