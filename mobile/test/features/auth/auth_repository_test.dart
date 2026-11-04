import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/platform/time_zone_service.dart';
import 'package:readin/core/push/push_service.dart';
import 'package:readin/features/auth/data/datasources/account_api.dart';
import 'package:readin/features/auth/data/datasources/account_device_data.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';

import '../../helpers/fake_auth.dart';

const googleToken = ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token');
const appleToken = ExternalCredential(
  provider: ExternalProvider.apple,
  idToken: 'apple-id-token',
  nonce: 'raw-nonce',
  authorizationCode: 'apple-authorization-code',
  displayName: 'Mona Adel',
);

class MockAuthApi extends Mock implements AuthApi {}

class MockAccountApi extends Mock implements AccountApi {}

class MockPushService extends Mock implements PushService {}

class MockTimeZone extends Mock implements TimeZoneService {}

class MockAccountDeviceData extends Mock implements AccountDeviceData {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RefreshRequest(''));
    registerFallbackValue(const LoginRequest(phoneNumber: '', password: ''));
    registerFallbackValue(const RegisterRequest(phoneNumber: '', password: '', recoveryPin: ''));
    registerFallbackValue(const ChangePasswordRequest(currentPassword: '', newPassword: ''));
    registerFallbackValue(const DeleteAccountRequest());
    registerFallbackValue(const ExternalSignInRequest(credential: googleToken));
    registerFallbackValue(const LinkExternalLoginRequest(credential: googleToken));
    registerFallbackValue(const AddPhoneSignInRequest(phoneNumber: '', password: '', recoveryPin: '', external: googleToken));
  });

  late MockAuthApi api;
  late MockAccountApi account;
  late MockPushService push;
  late FakeSecureStore secure;
  late AuthSessionStore store;
  late AuthRepositoryImpl auth;
  late AccountRepositoryImpl accounts;
  late MockAccountDeviceData device;
  late List<Me?> changes;

  setUp(() {
    api = MockAuthApi();
    account = MockAccountApi();
    push = MockPushService();
    secure = FakeSecureStore();
    store = AuthSessionStore(api, secure);
    final timeZone = MockTimeZone();
    when(timeZone.current).thenAnswer((_) async => 'Africa/Cairo');
    auth = AuthRepositoryImpl(api, account, store, push, timeZone);
    device = MockAccountDeviceData();
    when(() => device.forget()).thenAnswer((_) async {});
    accounts = AccountRepositoryImpl(account, store, device);
    changes = [];
    store.changes.listen(changes.add);
  });

  test('sign in stores the session and reports the user', () async {
    when(() => api.login(any())).thenAnswer((_) async => session('a1', 'r1'));

    final result = await auth.signIn(phoneNumber: '+12025550110', password: 'secret123');

    expect(result.valueOrNull?.phoneNumber, '+12025550110');
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r1');
    expect(await store.accessToken(), 'a1');
    await Future<void>.delayed(Duration.zero);
    expect(changes.single?.id, 'u-1');
  });

  test('register sends the UI language and the device time zone', () async {
    when(() => api.register(any())).thenAnswer((_) async => session('a1', 'r1'));

    await auth.register(phoneNumber: '+201001234567', password: 'reading4life', recoveryPin: '4831', uiLanguage: 'ar');

    final body = verify(() => api.register(captureAny())).captured.single as RegisterRequest;
    expect(body.toJson(), {
      'phoneNumber': '+201001234567',
      'password': 'reading4life',
      'recoveryPin': '4831',
      'uiLanguage': 'ar',
      'timeZone': 'Africa/Cairo',
    });
  });

  test('sign out: push token first (while the access token works), then the server, then locally', () async {
    await store.save(session('a1', 'r1'));
    final calls = <String>[];
    when(() => push.unregister()).thenAnswer((_) async => calls.add('DELETE /me/devices'));
    when(() => api.logout(any())).thenAnswer((_) async => calls.add('POST /auth/logout'));

    await auth.signOut();

    expect(calls, ['DELETE /me/devices', 'POST /auth/logout']);
    expect(verify(() => api.logout(captureAny())).captured.single.refreshToken, 'r1');
    expect(secure.values, isEmpty);
    expect(await store.accessToken(), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(changes.last, isNull);
  });

  test('sign out still ends the session locally when offline', () async {
    await store.save(session('a1', 'r1'));
    when(() => push.unregister()).thenAnswer((_) async {});
    when(() => api.logout(any())).thenThrow(offline('/auth/logout'));

    await auth.signOut();

    expect(secure.values, isEmpty);
  });

  test('a password change replaces the tokens', () async {
    await store.save(session('a1', 'r1'));
    when(() => account.changePassword(any())).thenAnswer((_) async => session('a2', 'r2'));

    await accounts.changePassword(currentPassword: 'old-pass1', newPassword: 'new-pass22');

    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r2');
    expect(await store.accessToken(), 'a2');
  });

  test('sign out everywhere replaces the tokens of this device', () async {
    await store.save(session('a1', 'r1'));
    when(() => account.logoutAll()).thenAnswer((_) async => session('a3', 'r3'));

    await auth.signOutEverywhere();

    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r3');
  });

  test('a deleted account is forgotten on this device: its data first, then the session', () async {
    await store.save(session('a1', 'r1'));
    when(() => account.deleteAccount(any())).thenAnswer((_) async {});
    when(() => device.forget()).thenAnswer((_) async {
      expect(secure.values, isNotEmpty, reason: 'the session ends last: ending it leaves the screen');
    });

    expect((await accounts.deleteAccount(password: 'right-pass1')).isOk, isTrue);

    verify(() => device.forget()).called(1);
    expect(secure.values, isEmpty);
    expect(await store.accessToken(), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(changes.last, isNull);
    expect(verify(() => account.deleteAccount(captureAny())).captured.single.toJson(), {'password': 'right-pass1'});
  });

  test('a failed deletion keeps everything: wrong password, Apple unreachable, offline (never queued)', () async {
    await store.save(session('a1', 'r1'));
    for (final error in [
      httpError('/me', 400, code: 'auth.wrong_password'),
      httpError('/me', 503, code: 'account.deletion_unavailable'),
      offline('/me'),
    ]) {
      when(() => account.deleteAccount(any())).thenThrow(error);
      final result = await accounts.deleteAccount(password: 'nope-12345');
      expect(result.isOk, isFalse);
    }

    expect(
      verify(() => account.deleteAccount(captureAny())).captured.map((r) => (r as DeleteAccountRequest).password),
      ['nope-12345', 'nope-12345', 'nope-12345'],
    );
    verifyNever(() => device.forget());
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r1');
    expect(await store.accessToken(), 'a1');
  });

  test('an account without a password is deleted with a fresh Google / Apple token, Apple with its code', () async {
    when(() => account.deleteAccount(any())).thenAnswer((_) async {});

    await accounts.deleteAccount(external: appleToken);

    expect(verify(() => account.deleteAccount(captureAny())).captured.single.toJson(), {
      'external': {
        'provider': 'apple',
        'idToken': 'apple-id-token',
        'nonce': 'raw-nonce',
        'authorizationCode': 'apple-authorization-code',
      },
    });
  });

  test("Apple's authorization code also goes with a link and with adding phone + password", () {
    expect(const LinkExternalLoginRequest(credential: appleToken, external: appleToken).toJson(), {
      'credential': {
        'provider': 'apple',
        'idToken': 'apple-id-token',
        'nonce': 'raw-nonce',
        'authorizationCode': 'apple-authorization-code',
      },
      'external': {
        'provider': 'apple',
        'idToken': 'apple-id-token',
        'nonce': 'raw-nonce',
        'authorizationCode': 'apple-authorization-code',
      },
    });
    expect(
      const AddPhoneSignInRequest(phoneNumber: '+201001234567', password: 'pw', recoveryPin: '4831', external: appleToken)
          .toJson()['external'],
      containsPair('authorizationCode', 'apple-authorization-code'),
    );
  });

  test('Google / Apple sign in sends the token, the language and the time zone, and stores the session', () async {
    when(() => api.external(any())).thenAnswer((_) async => session('a1', 'r1'));

    final result = await auth.signInWithExternal(appleToken, uiLanguage: 'ar');

    expect(result.isOk, isTrue);
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r1');
    expect(verify(() => api.external(captureAny())).captured.single.toJson(), {
      'provider': 'apple',
      'idToken': 'apple-id-token',
      'nonce': 'raw-nonce',
      'authorizationCode': 'apple-authorization-code',
      'displayName': 'Mona Adel',
      'uiLanguage': 'ar',
      'timeZone': 'Africa/Cairo',
    });
  });

  test('the not-linked answers: create an account, or link it to a phone sign in', () async {
    when(() => api.external(any())).thenAnswer((_) async => session('a1', 'r1'));

    await auth.signInWithExternal(googleToken, uiLanguage: 'en', createAccount: true);
    await auth.signInWithExternal(googleToken, uiLanguage: 'en', link: (phoneNumber: '+201001234567', password: 'pw-123456'));

    final bodies = verify(() => api.external(captureAny())).captured.cast<ExternalSignInRequest>();
    expect(bodies.first.toJson(), containsPair('createAccount', true));
    expect(bodies.first.toJson().containsKey('link'), isFalse);
    expect(bodies.last.toJson()['link'], {'phoneNumber': '+201001234567', 'password': 'pw-123456'});
    expect(bodies.last.toJson().containsKey('createAccount'), isFalse);
  });

  test('auth.external_not_linked keeps the user signed out', () async {
    when(() => api.external(any())).thenThrow(httpError('/auth/external', 404, code: 'auth.external_not_linked'));

    final result = await auth.signInWithExternal(googleToken, uiLanguage: 'ar');

    expect(result.failureOrNull?.code, 'auth.external_not_linked');
    expect(secure.values, isEmpty);
  });

  test('linking and unlinking publish the updated account', () async {
    final linked = meModel().copyWith(externalLogins: const [ExternalLoginModel(provider: 'google', email: 'r1@gmail.com')]);
    when(() => account.linkExternalLogin(any())).thenAnswer((_) async => linked);
    when(() => account.unlinkExternalLogin('google')).thenAnswer((_) async => meModel());

    await accounts.linkExternalLogin(googleToken, password: 'secret-1');
    await accounts.unlinkExternalLogin(ExternalProvider.google);

    expect(verify(() => account.linkExternalLogin(captureAny())).captured.single.toJson(), {
      'credential': {'provider': 'google', 'idToken': 'google-id-token'},
      'password': 'secret-1',
    });
    await Future<void>.delayed(Duration.zero);
    expect(changes.map((me) => me?.externalLogins.length), [1, 0]);
  });

  test('adding phone + password replaces the tokens', () async {
    await store.save(session('a1', 'r1'));
    when(() => account.addPhoneSignIn(any())).thenAnswer((_) async => session('a2', 'r2'));

    await accounts.addPhoneSignIn(phoneNumber: '+201001234567', password: 'pw-123456', recoveryPin: '4831', external: googleToken);

    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r2');
    expect(verify(() => account.addPhoneSignIn(captureAny())).captured.single.toJson(), {
      'phoneNumber': '+201001234567',
      'password': 'pw-123456',
      'recoveryPin': '4831',
      'external': {'provider': 'google', 'idToken': 'google-id-token'},
    });
  });

  test('the auth config lists the known Google / Apple providers; older APIs list none', () {
    expect(AuthConfigModel.fromJson(const {'externalProviders': ['google', 'apple', 'facebook']}).toEntity().externalProviders,
        [ExternalProvider.google, ExternalProvider.apple]);
    expect(AuthConfigModel.fromJson(const {}).toEntity().externalProviders, isEmpty);
  });

  test('the auth config falls back to the defaults offline and is fetched again later', () async {
    when(() => api.config()).thenThrow(offline('/auth/config'));
    expect((await auth.getConfig()).pinLength, 4);
    when(() => api.config()).thenAnswer((_) async => const AuthConfigModel(pinLength: 6));
    expect((await auth.getConfig()).pinLength, 6);
    expect((await auth.getConfig()).pinLength, 6);
    verify(() => api.config()).called(2);
  });

  test('MeDto with null links parses', () {
    final me = MeModel.fromJson({
      'id': 'u-1',
      'phoneNumber': '+12025550110',
      'email': null,
      'displayName': 'Reader 1',
      'username': 'reader1',
      'links': {'gitHub': null, 'linkedIn': 'https://linkedin.com/in/r1', 'website': null},
      'mustSetRecoveryPin': true,
      'isProfileComplete': false,
      'hasRecoveryPin': false,
    }).toEntity();
    expect(me.links, {'linkedIn': 'https://linkedin.com/in/r1'});
    expect(me.mustSetRecoveryPin, isTrue);
    expect(me.isProfileComplete, isFalse);
    expect(me.hasRecoveryPin, isFalse);
    // Without the Google/Apple fields (older API): a password, no external logins.
    expect(me.hasPassword, isTrue);
    expect(me.externalLogins, isEmpty);
  });

  test('MeDto with Google/Apple logins parses', () {
    final me = MeModel.fromJson({
      'id': 'u-1',
      'displayName': 'Reader 1',
      'username': 'reader1',
      'hasPassword': false,
      'externalLogins': [
        {'provider': 'google', 'email': 'r1@example.com', 'linkedAt': '2026-11-03T10:00:00Z'},
        {'provider': 'apple', 'email': null, 'linkedAt': '2026-11-03T11:00:00Z'},
      ],
    }).toEntity();
    expect(me.hasPassword, isFalse);
    expect(me.externalLogins, [
      ExternalLogin(provider: 'google', email: 'r1@example.com', linkedAt: DateTime.utc(2026, 11, 3, 10)),
      ExternalLogin(provider: 'apple', linkedAt: DateTime.utc(2026, 11, 3, 11)),
    ]);
  });
}
