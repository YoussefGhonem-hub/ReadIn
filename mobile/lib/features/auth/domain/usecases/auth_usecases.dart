import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/auth_config.dart';
import '../entities/me.dart';
import '../repositories/auth_repository.dart';

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
  const SignOut(this._auth);

  final AuthRepository _auth;

  Future<void> call() => _auth.signOut();
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

@injectable
class DeleteAccount {
  const DeleteAccount(this._accounts);

  final AccountRepository _accounts;

  Future<Result<void>> call(String password) => _accounts.deleteAccount(password);
}
