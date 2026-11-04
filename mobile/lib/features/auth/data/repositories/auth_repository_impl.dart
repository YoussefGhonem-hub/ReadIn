import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/platform/time_zone_service.dart';
import '../../../../core/push/push_service.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/account_api.dart';
import '../datasources/account_device_data.dart';
import '../datasources/auth_api.dart';
import '../datasources/auth_session_store.dart';
import '../models/auth_models.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._account, this._session, this._push, this._timeZone);

  final AuthApi _api;
  final AccountApi _account;
  final AuthSessionStore _session;
  final PushService _push;
  final TimeZoneService _timeZone;
  Future<AuthConfig>? _config;

  @override
  Stream<Me?> get sessionChanges => _session.changes;

  @override
  Failure? get sessionEndedBy => _session.endedBy;

  @override
  Future<AuthConfig> getConfig() => _config ??= guardApi(() async => (await _api.config()).toEntity()).then((result) {
        if (!result.isOk) _config = null; // try again next time
        return result.valueOrNull ?? AuthConfig.defaults;
      });

  @override
  Future<Result<Me?>> restoreSession() => _session.refresh();

  @override
  Future<Result<Me>> signIn({required String phoneNumber, required String password}) =>
      guardApi(() async => _session.save(await _api.login(LoginRequest(phoneNumber: phoneNumber, password: password))));

  @override
  Future<Result<Me>> register({
    required String phoneNumber,
    required String password,
    required String recoveryPin,
    required String uiLanguage,
  }) async {
    final timeZone = await _timeZone.current();
    return guardApi(() async => _session.save(await _api.register(RegisterRequest(
          phoneNumber: phoneNumber,
          password: password,
          recoveryPin: recoveryPin,
          uiLanguage: uiLanguage,
          timeZone: timeZone,
        ))));
  }

  @override
  Future<Result<Me>> signInWithExternal(
    ExternalCredential credential, {
    required String uiLanguage,
    bool createAccount = false,
    ExternalLink? link,
  }) async {
    final timeZone = await _timeZone.current();
    return guardApi(() async => _session.save(await _api.external(ExternalSignInRequest(
          credential: credential,
          uiLanguage: uiLanguage,
          timeZone: timeZone,
          linkPhoneNumber: link?.phoneNumber,
          linkPassword: link?.password,
          createAccount: createAccount,
        ))));
  }

  @override
  Future<Result<String>> verifyRecoveryPin({required String phoneNumber, required String pin}) =>
      guardApi(() async => (await _api.verifyPin(VerifyPinRequest(phoneNumber: phoneNumber, pin: pin))).resetToken);

  @override
  Future<Result<void>> resetPassword({required String resetToken, required String newPassword}) =>
      guardApi(() => _api.resetPassword(ResetPasswordRequest(resetToken: resetToken, newPassword: newPassword)));

  @override
  Future<void> signOut() async {
    await _push.unregister(); // needs the access token, so before anything else
    final token = await _session.refreshToken();
    if (token != null) await guardApi(() => _api.logout(RefreshRequest(token))); // 204 always; offline is fine too
    await _session.clear(); // the live connection and the FCM token follow the session (LiveSessionBridge)
  }

  @override
  Future<Result<Me>> signOutEverywhere() => guardApi(() async => _session.save(await _account.logoutAll()));
}

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._api, this._session, this._device);

  final AccountApi _api;
  final AuthSessionStore _session;
  final AccountDeviceData _device;

  Me _publish(MeModel model) {
    final me = model.toEntity();
    _session.updateUser(me);
    return me;
  }

  @override
  Future<Result<Me>> getMe() => guardApi(() async => _publish(await _api.getMe()));

  @override
  Future<Result<UsernameAvailability>> checkUsername(String username) =>
      guardApi(() async => (await _api.usernameAvailable(username)).toEntity());

  @override
  Future<Result<Me>> completeProfile({required String displayName, required String username, String? avatarUrl}) =>
      guardApi(() async => _publish(await _api.completeProfile(
            CompleteProfileRequest(displayName: displayName, username: username, avatarUrl: avatarUrl),
          )));

  @override
  Future<Result<Me>> setRecoveryPin(String pin) =>
      guardApi(() async => _publish(await _api.setRecoveryPin(SetRecoveryPinRequest(pin))));

  @override
  Future<Result<void>> changeRecoveryPin({required String currentPassword, required String newPin}) =>
      guardApi(() => _api.changeRecoveryPin(ChangeRecoveryPinRequest(currentPassword: currentPassword, newPin: newPin)));

  @override
  Future<Result<Me>> changePassword({required String currentPassword, required String newPassword}) => guardApi(
        () async => _session.save(
          await _api.changePassword(ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)),
        ),
      );

  @override
  Future<Result<Me>> changePhoneNumber({required String newPhoneNumber, required String currentPassword}) => guardApi(
        () async => _session.save(
          await _api.changePhone(ChangePhoneRequest(newPhoneNumber: newPhoneNumber, currentPassword: currentPassword)),
        ),
      );

  @override
  Future<Result<void>> deleteAccount({String? password, ExternalCredential? external}) async {
    final result = await guardApi(() => _api.deleteAccount(DeleteAccountRequest(password: password, external: external)));
    if (result.isOk) {
      // 204: the account is gone, with every session and device token. Forget what this device kept for it; the
      // session goes last, because ending it leaves the screen. Nothing happens here on a failure: never queued.
      await _device.forget();
      await _session.clear();
    }
    return result;
  }

  @override
  Future<Result<Me>> linkExternalLogin(ExternalCredential credential, {String? password, ExternalCredential? external}) =>
      guardApi(() async => _publish(await _api.linkExternalLogin(
            LinkExternalLoginRequest(credential: credential, password: password, external: external),
          )));

  @override
  Future<Result<Me>> unlinkExternalLogin(ExternalProvider provider) =>
      guardApi(() async => _publish(await _api.unlinkExternalLogin(provider.name)));

  @override
  Future<Result<Me>> addPhoneSignIn({
    required String phoneNumber,
    required String password,
    required String recoveryPin,
    required ExternalCredential external,
  }) =>
      guardApi(() async => _session.save(await _api.addPhoneSignIn(AddPhoneSignInRequest(
            phoneNumber: phoneNumber,
            password: password,
            recoveryPin: recoveryPin,
            external: external,
          ))));
}
