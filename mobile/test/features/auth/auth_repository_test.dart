import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/platform/time_zone_service.dart';
import 'package:readin/core/push/push_service.dart';
import 'package:readin/features/auth/data/datasources/account_api.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:readin/features/auth/domain/entities/me.dart';

import '../../helpers/fake_auth.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockAccountApi extends Mock implements AccountApi {}

class MockPushService extends Mock implements PushService {}

class MockTimeZone extends Mock implements TimeZoneService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RefreshRequest(''));
    registerFallbackValue(const LoginRequest(phoneNumber: '', password: ''));
    registerFallbackValue(const RegisterRequest(phoneNumber: '', password: '', recoveryPin: ''));
    registerFallbackValue(const ChangePasswordRequest(currentPassword: '', newPassword: ''));
    registerFallbackValue(const DeleteAccountRequest(''));
  });

  late MockAuthApi api;
  late MockAccountApi account;
  late MockPushService push;
  late FakeSecureStore secure;
  late AuthSessionStore store;
  late AuthRepositoryImpl auth;
  late AccountRepositoryImpl accounts;
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
    accounts = AccountRepositoryImpl(account, store);
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

  test('deleting the account forgets the session; a wrong password keeps it', () async {
    await store.save(session('a1', 'r1'));
    when(() => account.deleteAccount(any())).thenThrow(httpError('/me', 400, code: 'auth.wrong_password'));
    final wrong = await accounts.deleteAccount('nope');
    expect(wrong.failureOrNull?.code, 'auth.wrong_password');
    expect(secure.values, isNotEmpty);

    when(() => account.deleteAccount(any())).thenAnswer((_) async {});
    expect((await accounts.deleteAccount('right-pass1')).isOk, isTrue);
    expect(secure.values, isEmpty);
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
